import 'dart:convert';

import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/repository/asset_repository.dart';
import 'package:realunit_wallet/packages/repository/settings_repository.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/packages/utils/device_info.dart';
import 'package:realunit_wallet/packages/wallet/wallet_account.dart';
import 'package:realunit_wallet/screens/send/send_page.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DFXService extends DFXAuthService {
  DFXService(super.appStore, this._settingsRepository, this._assetRepository);

  final SettingsRepository _settingsRepository;
  final AssetRepository _assetRepository;
  bool _isLoading = false;

  String get title => 'DFX.swiss';

  @override
  AWalletAccount get wallet => appStore.wallet.currentAccount;

  @override
  String get walletAddress => wallet.primaryAddress.address.hexEip55;

  String get assetIn => 'EUR';

  String get assetOut => 'DEURO';

  String get langCode => _settingsRepository.language;

  bool get isAvailable => appStore.dfxAuthToken != null;

  static List<String> supportedAssets = [
    'Ethereum/DEURO',
    'Polygon/DEURO',
    'Base/DEURO',
    'Optimism/DEURO',
    'Arbitrum/DEURO',

    // 'Ethereum/ZCHF',
    // 'Polygon/ZCHF',
    // 'Base/ZCHF',
    // 'Optimism/ZCHF',
    // 'Arbitrum/ZCHF',

    'Ethereum/ETH',
    'Base/ETH',
    'Optimism/ETH',
    'Arbitrum/ETH',
    'Polygon/POL',

    // 'Ethereum/FPS',
    // 'Ethereum/WFPS',
    // 'Polygon/WFPS',
    // 'Ethereum/WBTC'
  ];

  // List<String> supportedAssets = [
  //   'ZCHF',
  //   'ETH',
  //   'Polygon/MATIC',
  //   'FPS',
  //   'WFPS',
  //   'WBTC'
  // ];
  //
  // List<String> supportedBlockchains = [
  //   'Ethereum',
  //   'Polygon',
  //   'Base',
  //   'Optimism',
  //   'Arbitrum',
  // ];

  String get blockchain => 'Ethereum';

  Future<void> launchProvider(BuildContext context, bool isBuyAction,
      {String? paymentMethod, Blockchain? blockchain, String? amount}) async {
    if (_isLoading) return;

    _isLoading = true;
    try {
      final actionType = isBuyAction ? '/buy' : '/sell';

      final accessToken = await getAuthToken();

      final uri = Uri.https(appStore.apiConfig.dfxAppHost, actionType, {
        'session': accessToken,
        'lang': langCode,
        'asset-out': isBuyAction ? assetOut : assetIn,
        'blockchain': blockchain?.name ?? this.blockchain,
        'asset-in': isBuyAction ? assetIn : assetOut,
        // 'blockchains': supportedBlockchains.join(','),
        'assets': supportedAssets.join(','),
        if (amount != null) 'amount-in': amount,
        // if (amount != null) 'amount-out': amount,
        if (paymentMethod != null) 'payment-method': paymentMethod,
        if (DeviceInfo.instance.isMobile) 'headless': 'true',
        'redirect-uri': 'deuro-wallet://dfx/callback'
      });

      _isLoading = false;
      if (await canLaunchUrl(uri)) {
        if (DeviceInfo.instance.isMobile) {
          if (context.mounted) {
            final response = await context.push('/webView',
                extra: WebViewRouteParams(title: title, url: uri));

            if (!isBuyAction && response != null && context.mounted) {
                completeSell(context, response as String);
            }
          }
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      _isLoading = false;
    }
  }

  Future<void> completeSell(
      BuildContext context, String callbackResponse) async {
    final uri = Uri.parse(callbackResponse);
    final params = uri.queryParameters;
    final depositAddress =
        await _getSellDepositAddress(params['routeId'] as String);

    final asset = (await _assetRepository.allAssets)
        .where((element) =>
            element.symbol.toUpperCase() == params['asset']!.toUpperCase() &&
            Blockchain.getFromChainId(element.chainId).name ==
                params['blockchain'])
        .firstOrNull;

    if (context.mounted) {
      context.push('/send',
          extra: SendRouteParams(
            asset: asset ?? dEUROAsset,
            receiver: depositAddress,
            amount: params['amount'] as String,
          ));
      // arguments: [depositAddress, params['amount'] as String, asset]
    }
  }

  Future<String> _getSellDepositAddress(String routeId) async {
    final uri = Uri.https(baseUrl, 'v1/sell/$routeId');

    final authToken = await getAuthToken();

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken'
      },
    );

    return jsonDecode(response.body)['deposit']['address'];
  }
}
