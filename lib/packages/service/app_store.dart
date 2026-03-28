import 'dart:developer' as developer;

import 'package:http/http.dart';
import 'package:realunit_wallet/models/node.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/cache_repository.dart';
import 'package:realunit_wallet/packages/repository/node_repository.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' as web3;

class AppStore {
  static const _dfxSignatureKey = 'dfx_cached_signature';
  static const _dfxSignatureAddressKey = 'dfx_cached_signature_address';

  final ApiConfig Function() getApiConfig;
  final CacheRepository _cacheRepository;
  final httpClient = Client();
  List<Node> _nodes = [];
  AWallet? _wallet;

  AppStore(this.getApiConfig, this._cacheRepository);

  set wallet(AWallet wallet_) => _wallet = wallet_;

  AWallet get wallet {
    if (_wallet != null) return _wallet!;
    throw Exception('No Wallet set');
  }

  ApiConfig get apiConfig => getApiConfig();

  Future<void> refreshNodes(NodeRepository nodeRepository) async {
    _nodes = await nodeRepository.allNodes;
  }

  String get primaryAddress => wallet.currentAccount.primaryAddress.address.hex;

  web3.Web3Client getClient(int chainId) {
    final node = _nodes.firstWhere(
      (node) => node.chainId == chainId,
      orElse: () {
        developer.log('No node found for $chainId using fallback ETH Node');
        return const Node(
          chainId: 1,
          name: 'Fallback',
          httpsUrl: 'https://eth-mainnet.g.alchemy.com/v2/9qEJRkxr1gAyFfwsCU6qODRSqj3TAzjj',
        );
      },
    );

    return web3.Web3Client(node.httpsUrl, httpClient);
  }

  String? dfxAuthToken;

  // Cached DFX signature — persisted in encrypted DB, reusable without hardware wallet
  String? _cachedSignature;
  String? _cachedSignatureAddress;

  String? get cachedDfxSignature => _cachedSignature;
  String? get cachedDfxSignatureAddress => _cachedSignatureAddress;

  Future<void> saveDfxSignature(String address, String signature) async {
    _cachedSignature = signature;
    _cachedSignatureAddress = address;
    await _cacheRepository.write(_dfxSignatureKey, signature);
    await _cacheRepository.write(_dfxSignatureAddressKey, address);
  }

  Future<void> loadCachedDfxSignature() async {
    _cachedSignature ??= await _cacheRepository.read(_dfxSignatureKey);
    _cachedSignatureAddress ??= await _cacheRepository.read(_dfxSignatureAddressKey);
  }

  void clearDfxSignature() {
    _cachedSignature = null;
    _cachedSignatureAddress = null;
    dfxAuthToken = null;
  }
}
