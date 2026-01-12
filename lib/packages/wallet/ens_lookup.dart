import 'dart:typed_data';

import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

/// Address of ENSRegistryWithFallback
const _mainnetEnsAddressContact = '0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e';

/// The ENS namespace includes both .eth names (which are native to ENS) and DNS names imported into ENS.
/// Because the DNS suffix namespace expands over time, a hardcoded list of name suffixes for recognizing ENS names will
/// regularly be out of date, leading to your application not recognizing all valid ENS names. To remain future-proof,
/// a correct integration of ENS treats any dot-separated name as a potential ENS name and will attempt a look-up.
///
/// via https://github.com/ensdomains/docs/blob/master/dapp-developer-guide/resolving-names.md#resolving-names

abstract class EnsLookup {
  static EnsLookup create(Web3Client client) => EnsLookupImpl(client: client);

  /// Returns ethereum address if ENS name can be resolved.
  Future<String?> resolveName(String domain);
}

class EnsLookupImpl extends EnsLookup {
  EnsLookupImpl({
    required this.client,
    this.ensContractAddress = _mainnetEnsAddressContact,
  });

  final Web3Client client;
  final String ensContractAddress;

  @override
  Future<String?> resolveName(String domain) async {
    if (domain.startsWith('.')) throw InvalidEnsName();

    // Get the resolver from the registry
    final resolverAddress = await _getResolver(domain);
    if (resolverAddress == null) return null;

    // keccak256('addr(bytes32)')
    final nodeHash = _hashDomainName(domain);
    final hexDataStr = '0x3b3b57de${nodeHash.substring(2)}';
    final data = hexToBytes(hexDataStr);

    final value = await _callContract(resolverAddress, data);

    if (value.length != 66) return null;
    final result = _hexToAddress(value);

    if (result == '0x0000000000000000000000000000000000000000') return null;
    return result;
  }

  /// Returns the entity resolver contract that corresponds to the given settings
  Future<String?> _getResolver(String domain) async {
    final nodeHash = _hashDomainName(domain);

    final hexDataStr = '0x0178b8bf${nodeHash.substring(2)}';
    final data = hexToBytes(hexDataStr);

    final value = await _callContract(ensContractAddress, data);

    if (value.length != 66) return null;
    final resolverAddress = _hexToAddress(value);

    if (resolverAddress == '0x0000000000000000000000000000000000000000') return null;
    return resolverAddress;
  }

  Future<String> _callContract(String to, Uint8List data) => client.callRaw(
        contract: EthereumAddress.fromHex(to),
        data: data,
      );

  /// Returns case sensitive checksummed version of Ethereum address
  String? _hexToAddress(String hexHash) {
    hexHash = hexHash.replaceFirst(RegExp(r'^0x'), '');

    if (hexHash.length != 64) return null;

    var addressDigits = hexHash.substring(24).toLowerCase();
    final chars = addressDigits.split('');
    final hashed = keccakUtf8(addressDigits);

    for (int i = 0; i < 40; i += 2) {
      if ((hashed[i >> 1] >> 4) >= 8) {
        chars[i] = addressDigits[i].toUpperCase();
      }
      if ((hashed[i >> 1] & 0x0f) >= 8) {
        chars[i + 1] = addressDigits[i + 1].toUpperCase();
      }
    }

    return '0x${chars.join()}';
  }

  /// Hashes the ethereum [domain] name
  String _hashDomainName(String domain) {
    domain = domain.toLowerCase();

    var result = List<int>.filled(32, 0);

    final terms = domain.split('.');

    for (String strTerm in terms.reversed) {
      final bytes = result + keccakUtf8(strTerm);
      final bytesHashed = keccak256(Uint8List.fromList(bytes));
      result = bytesHashed.toList();
    }
    return '0x${bytesToHex(result)}';
  }
}

class InvalidEnsName implements Exception {}
