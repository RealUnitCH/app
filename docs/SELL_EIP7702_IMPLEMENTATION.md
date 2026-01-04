# REALU Sell Implementation with EIP-7702 (Gasless Transactions)

This document provides a complete implementation guide for adding the REALU sell functionality to the realunit-app using EIP-7702 delegation for gasless transactions.

---

## IMPORTANT: Why This Works in realunit-app

The DFX services web app has a problem with EIP-7702: **MetaMask has disabled `eth_sign`**, which is required for signing EIP-7702 authorizations. Web apps cannot prompt users to sign raw hashes.

**However, the realunit-app is a native Flutter wallet app with direct private key access!**

| Context | eth_sign Problem | Solution |
|---------|------------------|----------|
| DFX services (Web) | ❌ MetaMask blocks eth_sign | wallet_sendCalls + Paymaster |
| **realunit-app (Native)** | ✅ No problem - has private key | Direct signing with secp256k1 |

The realunit-app can sign any hash directly using `secp256k1.sign()` from web3dart, bypassing all wallet provider restrictions.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Technical Feasibility](#2-technical-feasibility)
3. [Architecture](#3-architecture)
4. [Implementation Steps](#4-implementation-steps)
5. [EIP-712 Delegation Signing](#5-eip-712-delegation-signing)
6. [EIP-7702 Authorization Signing](#6-eip-7702-authorization-signing)
7. [API Endpoints](#7-api-endpoints)
8. [Data Models](#8-data-models)
9. [UI Implementation](#9-ui-implementation)
10. [Testing](#10-testing)
11. [Limitations](#11-limitations)

---

## 1. Overview

### Goal
Enable users to sell REALU tokens **without needing ETH for gas fees**. The DFX API supports EIP-7702 delegation, where users sign a delegation and authorization that allows a relayer to execute the transaction on their behalf.

### Flow Summary
```
User initiates sell
       ↓
App calls PUT /v1/sell/paymentInfos?includeTx=true
       ↓
API returns EIP-7702 data (if user has 0 ETH)
       ↓
User signs EIP-712 Delegation
       ↓
User signs EIP-7702 Authorization
       ↓
App calls PUT /v1/sell/paymentInfos/{id}/confirm with signatures
       ↓
Relayer executes transaction (pays gas)
       ↓
User receives CHF to bank account
```

---

## 2. Technical Feasibility

### Already Available in realunit-app

| Component | Status | Location |
|-----------|--------|----------|
| EIP-712 Signing | ✅ Ready | `lib/packages/wallet/eip712_signer.dart` |
| eth_sig_util_plus | ✅ v0.0.10 | `pubspec.yaml` |
| Private Key Access | ✅ Ready | `lib/packages/wallet/wallet_account.dart` |
| Keccak256 Hashing | ✅ Ready | `web3dart` package |
| RLP Encoding | ✅ Ready | `web3dart` package |
| DFX Auth Service | ✅ Ready | `lib/packages/service/dfx/dfx_auth_service.dart` |
| Buy Flow Pattern | ✅ Template | `lib/screens/buy/` |

### Needs Implementation

| Component | Effort | Description |
|-----------|--------|-------------|
| EIP-712 Delegation Signer | Low | Extend existing `EIP712Signer` |
| EIP-7702 Authorization Signer | Medium | New signer (~50 lines) |
| Sell API Service | Low | Analog to buy services |
| Sell UI Screen | Medium | Copy buy screen structure |

---

## 3. Architecture

### File Structure

```
lib/
├── packages/
│   ├── wallet/
│   │   ├── eip712_signer.dart           # Extend: add signDelegation()
│   │   └── eip7702_signer.dart          # NEW: EIP-7702 authorization
│   │
│   └── service/
│       └── dfx/
│           ├── sell_payment_info_service.dart    # NEW
│           ├── sell_price_service.dart           # NEW (optional)
│           └── models/
│               └── sell/
│                   ├── sell_payment_info_dto.dart      # NEW
│                   ├── sell_confirm_request_dto.dart   # NEW
│                   └── eip7702_data_dto.dart           # NEW
│
├── screens/
│   └── sell/                            # NEW: Complete sell flow
│       ├── sell_page.dart
│       ├── sell_view.dart
│       ├── cubits/
│       │   ├── sell_converter/
│       │   │   ├── sell_converter_cubit.dart
│       │   │   └── sell_converter_state.dart
│       │   └── sell_payment_info/
│       │       ├── sell_payment_info_cubit.dart
│       │       └── sell_payment_info_state.dart
│       └── widgets/
│           ├── sell_converter_widget.dart
│           └── sell_payment_details.dart
│
└── di.dart                              # Register new services
```

---

## 4. Implementation Steps

### Step 1: Add EIP-712 Delegation Signing

Extend `lib/packages/wallet/eip712_signer.dart`:

```dart
import 'dart:convert';
import 'package:eth_sig_util_plus/eth_sig_util_plus.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class EIP712Signer {
  // ... existing signRegistration method ...

  /// Signs an EIP-712 Delegation for EIP-7702 gasless transactions
  static String signDelegation({
    required EthPrivateKey credentials,
    required Map<String, dynamic> domain,
    required Map<String, dynamic> types,
    required Map<String, dynamic> message,
  }) {
    // Construct full EIP-712 typed data
    final Map<String, dynamic> typedDataMap = {
      "types": {
        "EIP712Domain": [
          {"name": "name", "type": "string"},
          {"name": "version", "type": "string"},
          {"name": "chainId", "type": "uint256"},
          {"name": "verifyingContract", "type": "address"},
        ],
        "Delegation": types["Delegation"],
        "Caveat": types["Caveat"],
      },
      "primaryType": "Delegation",
      "domain": domain,
      "message": message,
    };

    return EthSigUtil.signTypedData(
      privateKey: bytesToHex(credentials.privateKey, include0x: true),
      jsonData: jsonEncode(typedDataMap),
      version: TypedDataVersion.V4,
    );
  }
}
```

### Step 2: Create EIP-7702 Authorization Signer

Create `lib/packages/wallet/eip7702_signer.dart`:

```dart
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:web3dart/crypto.dart' as crypto;
import 'package:web3dart/web3dart.dart';

/// EIP-7702 Authorization Signer
///
/// Signs authorizations for account abstraction delegations.
/// Format: sign(keccak256(0x05 || rlp([chainId, address, nonce])))
///
/// IMPORTANT: This uses secp256k1.sign() directly because we need to sign
/// a pre-computed hash. Using signToEcSignature() would double-hash the data!
class EIP7702Signer {

  /// Signs an EIP-7702 authorization
  ///
  /// [credentials] - The user's private key
  /// [chainId] - The blockchain chain ID
  /// [contractAddress] - The delegator contract address
  /// [nonce] - The user's current account nonce
  ///
  /// Returns a map with: chainId, address, nonce, r, s, yParity
  static Map<String, dynamic> signAuthorization({
    required EthPrivateKey credentials,
    required int chainId,
    required String contractAddress,
    required int nonce,
  }) {
    // 1. RLP encode [chainId, address, nonce]
    final rlpData = _rlpEncode([
      _encodeInt(chainId),
      _encodeAddress(contractAddress),
      _encodeInt(nonce),
    ]);

    // 2. Prepend magic byte 0x05 (EIP-7702 prefix)
    final prefixedData = Uint8List(1 + rlpData.length);
    prefixedData[0] = 0x05;
    prefixedData.setRange(1, prefixedData.length, rlpData);

    // 3. Hash with keccak256
    final hash = crypto.keccak256(prefixedData);

    // 4. Sign the hash DIRECTLY using secp256k1.sign()
    //    DO NOT use signToEcSignature() - it would double-hash!
    final signature = crypto.sign(hash, credentials.privateKey);

    // 5. Extract r, s, yParity (v - 27)
    final r = '0x${signature.r.toRadixString(16).padLeft(64, '0')}';
    final s = '0x${signature.s.toRadixString(16).padLeft(64, '0')}';
    final yParity = signature.v - 27; // Convert v to yParity (0 or 1)

    return {
      'chainId': chainId,
      'address': contractAddress,
      'nonce': nonce,
      'r': r,
      's': s,
      'yParity': yParity,
    };
  }

  /// RLP encode a list of already-encoded items
  static Uint8List _rlpEncode(List<Uint8List> items) {
    // Concatenate all items
    int totalLength = 0;
    for (final item in items) {
      totalLength += item.length;
    }

    final payload = Uint8List(totalLength);
    int offset = 0;
    for (final item in items) {
      payload.setRange(offset, offset + item.length, item);
      offset += item.length;
    }

    // RLP list encoding
    if (totalLength <= 55) {
      final result = Uint8List(1 + totalLength);
      result[0] = 0xc0 + totalLength;
      result.setRange(1, result.length, payload);
      return result;
    } else {
      final lengthBytes = _encodeLength(totalLength);
      final result = Uint8List(1 + lengthBytes.length + totalLength);
      result[0] = 0xf7 + lengthBytes.length;
      result.setRange(1, 1 + lengthBytes.length, lengthBytes);
      result.setRange(1 + lengthBytes.length, result.length, payload);
      return result;
    }
  }

  /// RLP encode an integer
  static Uint8List _encodeInt(int value) {
    if (value == 0) {
      return Uint8List.fromList([0x80]); // Empty string for 0
    }
    if (value < 128) {
      return Uint8List.fromList([value]);
    }

    final bytes = _intToBytes(value);
    if (bytes.length == 1) {
      return bytes;
    }

    final result = Uint8List(1 + bytes.length);
    result[0] = 0x80 + bytes.length;
    result.setRange(1, result.length, bytes);
    return result;
  }

  /// RLP encode an address (20 bytes)
  static Uint8List _encodeAddress(String address) {
    final cleanAddress = address.toLowerCase().replaceFirst('0x', '');
    final bytes = hex.decode(cleanAddress);

    // Address is always 20 bytes, prefix with 0x80 + 20 = 0x94
    final result = Uint8List(21);
    result[0] = 0x94;
    result.setRange(1, 21, bytes);
    return result;
  }

  /// Convert integer to minimal bytes
  static Uint8List _intToBytes(int value) {
    if (value == 0) return Uint8List(0);

    final bytes = <int>[];
    while (value > 0) {
      bytes.insert(0, value & 0xff);
      value >>= 8;
    }
    return Uint8List.fromList(bytes);
  }

  /// Encode length for long RLP
  static Uint8List _encodeLength(int length) {
    return _intToBytes(length);
  }
}
```

### Step 3: Create Sell Payment Info Service

Create `lib/packages/service/dfx/sell_payment_info_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';

class SellPaymentInfoService {
  final AppStore _appStore;
  final DFXAuthService _authService;

  SellPaymentInfoService(this._appStore, this._authService);

  static const String _baseUrl = 'https://api.dfx.swiss';

  /// Creates a sell payment info request
  /// Returns the payment info including EIP-7702 data if user has no gas
  Future<SellPaymentInfoDto> createPaymentInfo({
    required String iban,
    required int assetId,
    required int currencyId,
    required double amount,
    bool exactPrice = false,
  }) async {
    final token = await _authService.getAuthToken();

    final response = await http.put(
      Uri.parse('$_baseUrl/v1/sell/paymentInfos?includeTx=true'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'iban': iban,
        'asset': {'id': assetId},
        'currency': {'id': currencyId},
        'amount': amount,
        'exactPrice': exactPrice,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create sell payment info: ${response.body}');
    }

    return SellPaymentInfoDto.fromJson(jsonDecode(response.body));
  }

  /// Confirms a sell transaction with EIP-7702 signatures
  Future<SellConfirmationDto> confirmSell({
    required int paymentInfoId,
    required Map<String, dynamic> delegation,
    required Map<String, dynamic> authorization,
  }) async {
    final token = await _authService.getAuthToken();

    final response = await http.put(
      Uri.parse('$_baseUrl/v1/sell/paymentInfos/$paymentInfoId/confirm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'eip7702': {
          'delegation': delegation,
          'authorization': authorization,
        },
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to confirm sell: ${response.body}');
    }

    return SellConfirmationDto.fromJson(jsonDecode(response.body));
  }
}

// DTOs
class SellPaymentInfoDto {
  final int id;
  final String depositAddress;
  final double estimatedAmount;
  final String? blockchain;
  final EIP7702DataDto? eip7702;
  final int? chainId;

  SellPaymentInfoDto({
    required this.id,
    required this.depositAddress,
    required this.estimatedAmount,
    this.blockchain,
    this.eip7702,
    this.chainId,
  });

  bool get hasEIP7702 => eip7702 != null;

  factory SellPaymentInfoDto.fromJson(Map<String, dynamic> json) {
    final depositTx = json['depositTx'] as Map<String, dynamic>?;

    return SellPaymentInfoDto(
      id: json['id'],
      depositAddress: json['depositAddress'],
      estimatedAmount: (json['estimatedAmount'] as num).toDouble(),
      blockchain: json['blockchain'],
      chainId: depositTx?['chainId'],
      eip7702: depositTx?['eip7702'] != null
          ? EIP7702DataDto.fromJson(depositTx!['eip7702'])
          : null,
    );
  }
}

class EIP7702DataDto {
  final String relayerAddress;
  final String delegationManagerAddress;
  final String delegatorAddress;
  final int userNonce;
  final Map<String, dynamic> domain;
  final Map<String, dynamic> types;
  final Map<String, dynamic> message;

  EIP7702DataDto({
    required this.relayerAddress,
    required this.delegationManagerAddress,
    required this.delegatorAddress,
    required this.userNonce,
    required this.domain,
    required this.types,
    required this.message,
  });

  factory EIP7702DataDto.fromJson(Map<String, dynamic> json) {
    return EIP7702DataDto(
      relayerAddress: json['relayerAddress'],
      delegationManagerAddress: json['delegationManagerAddress'],
      delegatorAddress: json['delegatorAddress'],
      userNonce: json['userNonce'],
      domain: json['domain'],
      types: json['types'],
      message: json['message'],
    );
  }
}

class SellConfirmationDto {
  final int id;
  final String? txId;
  final String? status;

  SellConfirmationDto({
    required this.id,
    this.txId,
    this.status,
  });

  factory SellConfirmationDto.fromJson(Map<String, dynamic> json) {
    return SellConfirmationDto(
      id: json['id'],
      txId: json['txId'],
      status: json['status'],
    );
  }
}
```

### Step 4: Create Sell Cubit

Create `lib/screens/sell/cubits/sell_payment_info/sell_payment_info_cubit.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/sell_payment_info_service.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';
import 'package:realunit_wallet/packages/wallet/eip7702_signer.dart';
import 'package:web3dart/web3dart.dart';

part 'sell_payment_info_state.dart';

class SellPaymentInfoCubit extends Cubit<SellPaymentInfoState> {
  final SellPaymentInfoService _sellService;
  final AppStore _appStore;

  SellPaymentInfoCubit(this._sellService, this._appStore)
      : super(SellPaymentInfoInitial());

  /// Creates a sell order and handles EIP-7702 signing if needed
  Future<void> createSellOrder({
    required String iban,
    required int assetId,
    required int currencyId,
    required double amount,
  }) async {
    emit(SellPaymentInfoLoading());

    try {
      // 1. Create payment info
      final paymentInfo = await _sellService.createPaymentInfo(
        iban: iban,
        assetId: assetId,
        currencyId: currencyId,
        amount: amount,
      );

      // 2. Check if EIP-7702 is available (user has no gas)
      if (paymentInfo.hasEIP7702) {
        emit(SellPaymentInfoNeedsSignature(paymentInfo));
      } else {
        // Normal flow - user needs to send tokens manually
        emit(SellPaymentInfoSuccess(paymentInfo, requiresManualTransfer: true));
      }
    } catch (e) {
      emit(SellPaymentInfoError(e.toString()));
    }
  }

  /// Signs and confirms the sell with EIP-7702
  Future<void> signAndConfirm(SellPaymentInfoDto paymentInfo) async {
    if (!paymentInfo.hasEIP7702) {
      emit(SellPaymentInfoError('EIP-7702 data not available'));
      return;
    }

    emit(SellPaymentInfoSigning());

    try {
      final wallet = _appStore.openWallet;
      if (wallet == null) {
        throw Exception('No wallet available');
      }

      final credentials = wallet.primaryAccount.primaryAddress;
      if (credentials is! EthPrivateKey) {
        throw Exception('Hardware wallets not supported for EIP-7702 signing');
      }

      final eip7702 = paymentInfo.eip7702!;
      final chainId = paymentInfo.chainId!;

      // 1. Sign EIP-712 Delegation
      final delegationSignature = EIP712Signer.signDelegation(
        credentials: credentials,
        domain: eip7702.domain,
        types: eip7702.types,
        message: eip7702.message,
      );

      final delegation = {
        'delegate': eip7702.message['delegate'],
        'delegator': eip7702.message['delegator'],
        'authority': eip7702.message['authority'],
        'salt': eip7702.message['salt'].toString(),
        'signature': delegationSignature,
      };

      // 2. Sign EIP-7702 Authorization
      final authorization = EIP7702Signer.signAuthorization(
        credentials: credentials,
        chainId: chainId,
        contractAddress: eip7702.delegatorAddress,
        nonce: eip7702.userNonce,
      );

      // 3. Confirm with API
      final confirmation = await _sellService.confirmSell(
        paymentInfoId: paymentInfo.id,
        delegation: delegation,
        authorization: authorization,
      );

      emit(SellPaymentInfoConfirmed(confirmation));
    } catch (e) {
      emit(SellPaymentInfoError(e.toString()));
    }
  }
}
```

---

## 5. EIP-712 Delegation Signing

### Domain Structure (provided by API)
```json
{
  "name": "DelegationManager",
  "version": "1",
  "chainId": 11155111,
  "verifyingContract": "0xdb9B1e94B5b69Df7e401DDbedE43491141047dB3"
}
```

### Types Structure
```json
{
  "Delegation": [
    { "name": "delegate", "type": "address" },
    { "name": "delegator", "type": "address" },
    { "name": "authority", "type": "bytes32" },
    { "name": "caveats", "type": "Caveat[]" },
    { "name": "salt", "type": "uint256" }
  ],
  "Caveat": [
    { "name": "enforcer", "type": "address" },
    { "name": "terms", "type": "bytes" }
  ]
}
```

### Message Structure
```json
{
  "delegate": "0x<relayer_address>",
  "delegator": "0x<user_address>",
  "authority": "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
  "caveats": [],
  "salt": "1234567890"
}
```

---

## 6. EIP-7702 Authorization Signing

### Format
```
signature = sign(keccak256(0x05 || rlp([chainId, contractAddress, nonce])))
```

### Contract Addresses (constant on all EVM chains)
```
Delegator Contract:         0x63c0c19a282a1b52b07dd5a65b58948a07dae32b
DelegationManager Contract: 0xdb9B1e94B5b69Df7e401DDbedE43491141047dB3
```

### Result Structure
```json
{
  "chainId": 11155111,
  "address": "0x63c0c19a282a1b52b07dd5a65b58948a07dae32b",
  "nonce": 0,
  "r": "0x...",
  "s": "0x...",
  "yParity": 0
}
```

---

## 7. API Endpoints

### Authentication
```
GET  /v1/auth/signMessage?address={address}  → { message: string }
POST /v1/auth                                 → { accessToken: string }
```

### Sell Flow
```
PUT  /v1/sell/paymentInfos?includeTx=true    → SellPaymentInfoDto
PUT  /v1/sell/paymentInfos/{id}/confirm      → SellConfirmationDto
```

### Request: Create Payment Info
```json
{
  "iban": "CH9300762011623852957",
  "asset": { "id": 407 },
  "currency": { "id": 1 },
  "amount": 10,
  "exactPrice": false
}
```

### Request: Confirm with EIP-7702
```json
{
  "eip7702": {
    "delegation": {
      "delegate": "0x...",
      "delegator": "0x...",
      "authority": "0xff...ff",
      "salt": "1234567890",
      "signature": "0x..."
    },
    "authorization": {
      "chainId": 11155111,
      "address": "0x63c0c19a282a1b52b07dd5a65b58948a07dae32b",
      "nonce": 0,
      "r": "0x...",
      "s": "0x...",
      "yParity": 0
    }
  }
}
```

---

## 8. Data Models

### Asset IDs
| Asset | ID | Decimals | Blockchain |
|-------|-----|----------|------------|
| REALU | 407 | 0 | Sepolia |

### Currency IDs
| Currency | ID |
|----------|-----|
| CHF | 1 |
| EUR | 2 |

---

## 9. UI Implementation

### Sell Page Structure
```dart
class SellPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<SellConverterCubit>()),
        BlocProvider(create: (_) => getIt<SellPaymentInfoCubit>()),
      ],
      child: const SellView(),
    );
  }
}
```

### User Flow
1. User enters REALU amount to sell
2. App shows estimated CHF amount
3. User enters IBAN
4. User taps "Sell"
5. If EIP-7702 available:
   - Show signing confirmation dialog
   - Sign both signatures
   - Show success
6. If no EIP-7702:
   - Show deposit address
   - User must have ETH and send manually

---

## 10. Testing

### Unit Tests for EIP-7702 Signer
```dart
void main() {
  test('EIP7702Signer generates correct authorization', () {
    final privateKey = EthPrivateKey.fromHex('0x...');

    final auth = EIP7702Signer.signAuthorization(
      credentials: privateKey,
      chainId: 11155111,
      contractAddress: '0x63c0c19a282a1b52b07dd5a65b58948a07dae32b',
      nonce: 0,
    );

    expect(auth['chainId'], 11155111);
    expect(auth['r'], startsWith('0x'));
    expect(auth['s'], startsWith('0x'));
    expect(auth['yParity'], anyOf(0, 1));
  });
}
```

### Integration Test
Use the `scripts/sell-realu.js` from the API repo as reference implementation.

---

## 11. Limitations

### Hardware Wallets Not Supported
BitBox and other hardware wallets cannot sign EIP-712 typed data for arbitrary domains, nor can they sign raw hashes for EIP-7702. The sell flow with EIP-7702 is **only available for software wallets**.

**Fallback for Hardware Wallets:**
- Show deposit address
- User must have ETH and transfer tokens manually
- Or: Don't offer sell for hardware wallets

### Network Requirements
- EIP-7702 is part of Ethereum's Pectra upgrade
- Only works on chains that support EIP-7702
- The API checks if EIP-7702 is available and only returns the data if supported

---

## 12. Comparison: Web vs Native App

This section clarifies why EIP-7702 works in realunit-app but not in the DFX web services app.

### The Problem in Web Apps (DFX services)

According to the analysis in `services/docs/EIP7702-ANALYSE.md`:

| Issue | Impact |
|-------|--------|
| MetaMask disabled `eth_sign` | Cannot sign raw keccak256 hashes |
| Security restriction | Wallets control EIP-7702, not apps |
| No workaround | `personal_sign` adds prefix, `eth_signTypedData_v4` uses EIP-712 domain |

**Quote from Biconomy:**
> "Currently, DApps cannot prompt standard browser wallet accounts to sign EIP-7702 'authorizations'. DApp developers can only prompt embedded EOAs (and Local Accounts) to sign authorizations."

### Why Native Apps Are Different

The realunit-app is a **native wallet app** with:

| Feature | Benefit |
|---------|---------|
| Direct private key access | Can call `secp256k1.sign()` directly |
| No wallet provider | No MetaMask/browser restrictions |
| Full crypto library access | `web3dart/crypto.dart` exports `sign()` |

**The app IS the wallet** - there's no external wallet blocking operations.

### Solution for Web: wallet_sendCalls (Not needed for realunit-app)

For web apps, the solution is `wallet_sendCalls` (ERC-5792) with a Paymaster:
- MetaMask handles EIP-7702 internally
- Paymaster pays gas fees
- No `eth_sign` required

**This is NOT needed for realunit-app** because we have direct signing capability.

---

## Summary

The EIP-7702 sell implementation is **fully feasible** in realunit-app:

| Component | Status | Method |
|-----------|--------|--------|
| **EIP-712 Delegation** | ✅ Ready | `eth_sig_util_plus.signTypedData()` |
| **EIP-7702 Authorization** | ✅ Implementable | `crypto.sign()` (direct hash signing) |
| **API Integration** | ✅ Standard | REST calls like buy flow |
| **UI** | ✅ Template exists | Copy buy screen structure |

### Critical Implementation Notes

1. **Use `crypto.sign()` NOT `signToEcSignature()`** for EIP-7702
   - `signToEcSignature()` calls `keccak256()` internally → double hashing
   - `crypto.sign()` signs the hash directly → correct

2. **Hardware wallets cannot use gasless sell**
   - BitBox cannot sign arbitrary hashes
   - Fallback: normal transfer (requires ETH)

3. **The MetaMask problem does NOT apply here**
   - realunit-app has direct private key access
   - No wallet provider restrictions

**Estimated effort:** 2-3 days for complete implementation including UI.
