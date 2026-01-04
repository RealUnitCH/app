import 'package:flutter/widgets.dart';
import 'package:realunit_wallet/generated/i18n.dart';

/// Network mode for API calls
enum NetworkMode {
  /// Production/Mainnet - uses api.dfx.swiss
  mainnet,

  /// Development/Testnet - uses dev.api.dfx.swiss
  testnet;

  String get displayName => switch (this) {
        NetworkMode.mainnet => 'Mainnet',
        NetworkMode.testnet => 'Testnet',
      };

  String localizedName(BuildContext context) => switch (this) {
        NetworkMode.mainnet => S.of(context).network_mainnet,
        NetworkMode.testnet => S.of(context).network_testnet,
      };

  bool get isTestnet => this == NetworkMode.testnet;
  bool get isMainnet => this == NetworkMode.mainnet;
}

/// Central API configuration that provides URLs based on network mode
class ApiConfig {
  final NetworkMode networkMode;

  const ApiConfig({required this.networkMode});

  /// Base URL for DFX API (without protocol)
  String get dfxApiHost => networkMode.isTestnet
      ? 'dev.api.dfx.swiss'
      : 'api.dfx.swiss';

  /// Base URL for DFX Services/App (without protocol)
  String get dfxServicesHost => networkMode.isTestnet
      ? 'dev.app.dfx.swiss'
      : 'app.dfx.swiss';

  /// Full base URL for DFX API (with https)
  String get dfxApiBaseUrl => 'https://$dfxApiHost';

  /// Full base URL for DFX Services (with https)
  String get dfxServicesBaseUrl => 'https://$dfxServicesHost';

  // Specific endpoint URLs
  String get realUnitPriceHistoryUrl =>
      '$dfxApiBaseUrl/v1/realunit/price/history?timeFrame=ALL';

  String get realUnitPriceUrl =>
      '$dfxApiBaseUrl/v1/realunit/price';

  String get realUnitBrokerbotBaseUrl =>
      '$dfxApiBaseUrl/v1/realunit/brokerbot';

  String realUnitAccountHistoryUrl(String address) =>
      '$dfxApiBaseUrl/v1/realunit/account/$address/history';
}
