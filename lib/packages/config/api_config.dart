import 'package:flutter/widgets.dart';
import 'package:realunit_wallet/generated/i18n.dart';

class ApiConfig {
  final NetworkMode networkMode;

  const ApiConfig({required this.networkMode});

  /// Base URL for DFX API (without protocol)
  String get apiHost => networkMode.isTestnet ? 'dev.api.dfx.swiss' : 'api.dfx.swiss';

  /// Base URL for DFX App/Frontend (without protocol)
  String get appHost => networkMode.isTestnet ? 'dev.app.dfx.swiss' : 'app.dfx.swiss';
}

enum NetworkMode {
  mainnet('Mainnet'),
  testnet('Testnet');

  const NetworkMode(this.name);

  final String name;

  String localizedName(BuildContext context) => switch (this) {
        NetworkMode.mainnet => S.of(context).network_mainnet,
        NetworkMode.testnet => S.of(context).network_testnet,
      };

  bool get isTestnet => this == NetworkMode.testnet;
  bool get isMainnet => this == NetworkMode.mainnet;
}
