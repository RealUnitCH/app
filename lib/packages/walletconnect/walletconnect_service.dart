import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/eip712_signer.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/signing_cancelled_exception.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_allowlist.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_config.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_engine.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_uri.dart';

enum WalletConnectServiceErrorType {
  unsupportedProvider,
  invalidVerification,
  invalidUri,
  unsupportedMethod,
  sendTransactionUnsupported,
  signingFailed,
  sessionEnded,
}

final class WalletConnectServiceError {
  final WalletConnectServiceErrorType type;
  final String message;

  const WalletConnectServiceError(this.type, this.message);
}

sealed class WalletConnectUserPrompt {
  const WalletConnectUserPrompt();

  String? get originUrl;
}

final class WalletConnectProposalPrompt extends WalletConnectUserPrompt {
  final WalletConnectSessionProposal proposal;

  const WalletConnectProposalPrompt(this.proposal);

  @override
  String? get originUrl => proposal.originUrl;
}

final class WalletConnectRequestPrompt extends WalletConnectUserPrompt {
  final WalletConnectSessionRequest request;
  final String messagePreview;

  const WalletConnectRequestPrompt({
    required this.request,
    required this.messagePreview,
  });

  @override
  String? get originUrl => request.originUrl;
}

typedef WalletConnectMessageSigner = Future<String> Function(String message);
typedef WalletConnectTypedDataSigner = Future<String> Function(
  int chainId,
  String jsonData,
);

class WalletConnectService {
  static const sendTransactionUnsupportedMessage =
      'Sending transactions over WalletConnect is not supported.';
  static const invalidVerificationMessage =
      'WalletConnect could not verify this provider.';
  static const invalidUriMessage = 'This is not a valid WalletConnect URI.';
  static const signingFailedMessage = 'Debug wallets cannot sign.';
  static const sessionEndedMessage = 'The WalletConnect session ended.';

  final WalletConnectEngine _engine;
  final WalletService? _walletService;
  final AppStore? _appStore;
  final String? _testAddress;
  final WalletConnectMessageSigner? _testMessageSigner;
  final WalletConnectTypedDataSigner? _testTypedDataSigner;
  final WalletType? _testWalletType;

  final _prompts = StreamController<WalletConnectUserPrompt>.broadcast();
  final _errors = StreamController<WalletConnectServiceError>.broadcast();

  Future<void>? _initialization;
  bool _initialized = false;
  bool _sessionLive = false;

  // coverage:ignore-start — production ctor needs WalletService/AppStore; tests use forTesting
  WalletConnectService({
    required WalletConnectEngine engine,
    required WalletService walletService,
    required AppStore appStore,
  })  : _engine = engine,
        _walletService = walletService,
        _appStore = appStore,
        _testAddress = null,
        _testMessageSigner = null,
        _testTypedDataSigner = null,
        _testWalletType = null {
    _listen();
  }
  // coverage:ignore-end

  WalletConnectService.forTesting({
    required WalletConnectEngine engine,
    required String address,
    required WalletConnectMessageSigner signMessage,
    WalletConnectTypedDataSigner? signTypedData,
    WalletType? walletType,
  })  : _engine = engine,
        _walletService = null,
        _appStore = null,
        _testAddress = address,
        _testMessageSigner = signMessage,
        _testTypedDataSigner = signTypedData,
        _testWalletType = walletType {
    _listen();
  }

  Stream<WalletConnectUserPrompt> get prompts => _prompts.stream;
  Stream<WalletConnectServiceError> get errors => _errors.stream;

  String get _address => _testAddress ?? _appStore!.primaryAddress;

  WalletType get _walletType {
    if (_appStore != null) return _appStore.wallet.walletType;
    return _testWalletType ?? WalletType.software;
  }

  void _listen() {
    _engine.events.listen((event) {
      unawaited(
        _handleIncoming(event).catchError((Object error, StackTrace stackTrace) {
          developer.log(
            'WalletConnect event handling failed',
            error: error,
            stackTrace: stackTrace,
          );
        }),
      );
    });
  }

  Future<void> ensureInitialized() {
    if (_initialized) return Future.value();
    if (_appStore != null && !_appStore.isWalletLoaded) return Future.value();
    return _initialization ??= _initialize().whenComplete(() {
      _initialization = null;
    });
  }

  /// Tears down active WalletConnect sessions/pairings so a new wallet can
  /// re-init after Delete Wallet / Forgot PIN.
  Future<void> reset() async {
    await _engine.reset();
    _initialized = false;
    _initialization = null;
    _sessionLive = false;
  }

  Future<void> _initialize() async {
    try {
      await _engine.init(
        address: _address,
        chainIds: WalletConnectConfig.chainIds,
      );
      _initialized = true;
    } catch (error, stackTrace) {
      developer.log(
        'WalletConnect initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> pair(String uri) async {
    final pairingUri = WalletConnectUri.extractPairingUri(uri);
    if (pairingUri == null) {
      throw const FormatException(invalidUriMessage);
    }
    await ensureInitialized();
    if (!_initialized) throw StateError('WalletConnect is not initialized.');
    await _engine.pair(pairingUri);
    _sessionLive = true;
  }

  Future<void> _handleIncoming(WalletConnectIncoming incoming) async {
    switch (incoming) {
      case WalletConnectSessionProposal():
        if (!_isAccepted(incoming.originUrl, incoming.verifyStatus)) {
          _sessionLive = false;
          try {
            await _engine.rejectSession(incoming.proposalId);
          } finally {
            _emitPolicyError(incoming.originUrl, incoming.verifyStatus);
          }
          return;
        }
        _sessionLive = true;
        _prompts.add(WalletConnectProposalPrompt(incoming));
      case WalletConnectSessionRequest():
        if (!_isAccepted(incoming.originUrl, incoming.verifyStatus)) {
          _sessionLive = false;
          try {
            try {
              await _engine.rejectRequest(incoming.requestId);
            } finally {
              await _engine.disconnect(incoming.topic);
            }
          } finally {
            _emitPolicyError(incoming.originUrl, incoming.verifyStatus);
          }
          return;
        }
        _sessionLive = true;
        await _handleRequest(incoming);
      case WalletConnectSessionDeleted():
        _sessionLive = false;
        _errors.add(
          const WalletConnectServiceError(
            WalletConnectServiceErrorType.sessionEnded,
            sessionEndedMessage,
          ),
        );
    }
  }

  bool _isAccepted(String? origin, WalletConnectVerifyStatus status) =>
      status == WalletConnectVerifyStatus.valid &&
      WalletConnectAllowlist.isAllowedOrigin(origin);

  void _emitPolicyError(String? origin, WalletConnectVerifyStatus status) {
    if (!WalletConnectAllowlist.isAllowedOrigin(origin)) {
      _errors.add(
        const WalletConnectServiceError(
          WalletConnectServiceErrorType.unsupportedProvider,
          WalletConnectAllowlist.unsupportedProviderMessage,
        ),
      );
      return;
    }
    _errors.add(
      const WalletConnectServiceError(
        WalletConnectServiceErrorType.invalidVerification,
        invalidVerificationMessage,
      ),
    );
  }

  Future<void> _handleRequest(WalletConnectSessionRequest request) async {
    switch (request.method) {
      case 'eth_accounts':
      case 'eth_requestAccounts':
        await _engine.approveRequest(request.requestId, jsonEncode([_address]));
      case 'eth_chainId':
        final chainId = WalletConnectConfig.chainIds.contains(request.chainId)
            ? request.chainId!
            : 1;
        await _engine.approveRequest(
          request.requestId,
          '0x${chainId.toRadixString(16)}',
        );
      case 'wallet_switchEthereumChain':
        final chainId = _requestedChainId(request.params);
        if (chainId != null && WalletConnectConfig.chainIds.contains(chainId)) {
          await _engine.approveRequest(request.requestId, 'null');
        } else {
          await _engine.rejectRequest(request.requestId);
        }
      case 'personal_sign':
      case 'eth_sign':
        if (_walletType == WalletType.debug) {
          await _rejectDebugSigning(request.requestId);
          return;
        }
        _prompts.add(
          WalletConnectRequestPrompt(
            request: request,
            messagePreview: _messageFromParams(request.params),
          ),
        );
      case 'eth_signTypedData':
      case 'eth_signTypedData_v4':
        if (_walletType == WalletType.debug) {
          await _rejectDebugSigning(request.requestId);
          return;
        }
        _prompts.add(
          WalletConnectRequestPrompt(
            request: request,
            messagePreview: _typedDataJson(request.params) ?? '',
          ),
        );
      case 'eth_signTransaction':
      case 'eth_sendTransaction':
        await _rejectUnsupportedTransaction(request.requestId);
      default:
        await _engine.rejectRequest(request.requestId);
        _errors.add(
          WalletConnectServiceError(
            WalletConnectServiceErrorType.unsupportedMethod,
            'WalletConnect method ${request.method} is not supported.',
          ),
        );
    }
  }

  Future<void> approvePrompt(WalletConnectUserPrompt prompt) async {
    if (!_sessionLive) {
      throw StateError(sessionEndedMessage);
    }
    switch (prompt) {
      case WalletConnectProposalPrompt():
        await _engine.approveSession(
          prompt.proposal.proposalId,
          address: _address,
        );
      case WalletConnectRequestPrompt():
        final request = prompt.request;
        switch (request.method) {
          case 'personal_sign':
          case 'eth_sign':
            final signature = await _signMessage(
              _messageFromParams(request.params),
            );
            await _respondSignature(request.requestId, signature);
          case 'eth_signTypedData':
          case 'eth_signTypedData_v4':
            final jsonData = _typedDataJson(request.params);
            if (jsonData == null) {
              await _engine.rejectRequest(request.requestId);
              throw const FormatException('Invalid EIP-712 typed data.');
            }
            final chainId = request.chainId;
            if (chainId == null || !WalletConnectConfig.chainIds.contains(chainId)) {
              await _engine.rejectRequest(request.requestId);
              throw const FormatException('Unsupported WalletConnect chain.');
            }
            String signature;
            try {
              signature = await _signTypedData(chainId, jsonData);
            } on SigningCancelledException {
              await _engine.rejectRequest(request.requestId);
              rethrow;
            }
            await _respondSignature(request.requestId, signature);
          default:
            await _engine.rejectRequest(request.requestId);
        }
    }
  }

  Future<void> rejectPrompt(WalletConnectUserPrompt prompt) async {
    switch (prompt) {
      case WalletConnectProposalPrompt():
        await _engine.rejectSession(prompt.proposal.proposalId);
      case WalletConnectRequestPrompt():
        await _engine.rejectRequest(prompt.request.requestId);
    }
  }

  Future<String> _signMessage(String message) async {
    final testSigner = _testMessageSigner;
    if (testSigner != null) return testSigner(message);

    // coverage:ignore-start — live wallet unlock/sign cannot run in flutter test without a real wallet
    await _walletService!.ensureCurrentWalletUnlocked();
    try {
      return await _appStore!.wallet.currentAccount.signMessage(message);
    } finally {
      await _walletService.lockCurrentWallet();
    }
    // coverage:ignore-end
  }

  Future<String> _signTypedData(int chainId, String jsonData) async {
    final testSigner = _testTypedDataSigner;
    if (testSigner != null) return testSigner(chainId, jsonData);

    // coverage:ignore-start — live EIP-712 sign cannot run in flutter test without a real wallet
    await _walletService!.ensureCurrentWalletUnlocked();
    try {
      return await Eip712Signer.signTypedDataJson(
        credentials: _appStore!.wallet.currentAccount.primaryAddress,
        chainId: chainId,
        jsonData: jsonData,
      );
    } finally {
      await _walletService.lockCurrentWallet();
    }
    // coverage:ignore-end
  }

  Future<void> _rejectUnsupportedTransaction(int requestId) async {
    await _engine.rejectRequest(requestId);
    _errors.add(
      const WalletConnectServiceError(
        WalletConnectServiceErrorType.sendTransactionUnsupported,
        sendTransactionUnsupportedMessage,
      ),
    );
  }

  Future<void> _respondSignature(int requestId, String signature) async {
    if (signature.isEmpty || signature == '0x') {
      await _engine.rejectRequest(requestId);
      throw const SigningCancelledException();
    }
    await _respondIfSessionLive(requestId, signature);
  }

  Future<void> _respondIfSessionLive(int requestId, String signature) async {
    if (!_sessionLive) {
      await _engine.rejectRequest(requestId);
      throw StateError(sessionEndedMessage);
    }
    await _engine.approveRequest(requestId, signature);
  }

  Future<void> _rejectDebugSigning(int requestId) async {
    await _engine.rejectRequest(requestId);
    _errors.add(
      const WalletConnectServiceError(
        WalletConnectServiceErrorType.signingFailed,
        signingFailedMessage,
      ),
    );
  }

  int? _requestedChainId(dynamic params) {
    if (params is! List || params.isEmpty || params.first is! Map) return null;
    final value = (params.first as Map)['chainId'];
    if (value is! String) return null;
    final normalized = value.toLowerCase();
    if (normalized.startsWith('0x')) {
      return int.tryParse(normalized.substring(2), radix: 16);
    }
    return int.tryParse(normalized);
  }

  String _messageFromParams(dynamic params) {
    if (params is! List || params.isEmpty) return '';
    final address = _address.toLowerCase();
    String? value;
    for (final param in params) {
      if (param is String && param.toLowerCase() != address) {
        value = param;
        break;
      }
    }
    value ??= params.whereType<String>().firstOrNull ?? '';
    return _decodeHexUtf8(value);
  }

  String _decodeHexUtf8(String value) {
    if (!value.startsWith('0x')) return value;
    final hex = value.substring(2);
    if (hex.isEmpty || hex.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
      return value;
    }
    try {
      final bytes = <int>[
        for (var i = 0; i < hex.length; i += 2)
          int.parse(hex.substring(i, i + 2), radix: 16),
      ];
      return utf8.decode(bytes, allowMalformed: true);
    } on FormatException {
      // utf8.decode(allowMalformed: true) does not throw for tested inputs.
      return value; // coverage:ignore-line
    }
  }

  String? _typedDataJson(dynamic params) {
    if (params is! List) return null;
    for (final param in params) {
      if (param is Map) return jsonEncode(param);
      if (param is String && param.trimLeft().startsWith('{')) return param;
    }
    return null;
  }
}
