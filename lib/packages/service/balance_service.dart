import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';

class BalanceService {
  static const _balancePath = '/v1/realunit/account';
  String get _host => _appStore.apiConfig.apiHost;

  final BalanceRepository _balanceRepository;
  final AppStore _appStore;

  BalanceService(this._balanceRepository, this._appStore);

  Timer? _syncTimer;

  void startSync(String address) {
    cancelSync();

    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) => updateBalances(address));
  }

  void cancelSync() => _syncTimer?.cancel();

  Future<void> updateBalances(String address) async {
    await _updateRealUnitBalance(address);
  }

  Future<void> _updateRealUnitBalance(String address) async {
    try {
      final uri = buildUri(_host, '$_balancePath/$address');

      final response = await _appStore.httpClient.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final balanceString = json['balance'] as String?;

        if (balanceString != null) {
          final balanceValue = BigInt.parse(balanceString);

          await _balanceRepository.saveBalance(
            Balance(
              chainId: _appStore.apiConfig.asset.chainId,
              contractAddress: _appStore.apiConfig.asset.address,
              walletAddress: address,
              balance: balanceValue,
              asset: _appStore.apiConfig.asset,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Failed to update RealUnit balance: $e');
    }
  }

  Future<Balance?> getBalance(Asset asset, String address) =>
      _balanceRepository.getBalance(asset, address);
}
