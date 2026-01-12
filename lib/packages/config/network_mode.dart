import 'package:flutter/widgets.dart';
import 'package:realunit_wallet/generated/i18n.dart';

enum NetworkMode {
  mainnet('Mainnet'),
  testnet('Testnet');

  const NetworkMode(this.name);

  final String name;

  String localizedName(BuildContext context) => switch (this) {
        NetworkMode.mainnet => S.of(context).networkMainnet,
        NetworkMode.testnet => S.of(context).networkTestnet,
      };

  bool get isTestnet => this == NetworkMode.testnet;
  bool get isMainnet => this == NetworkMode.mainnet;
}
