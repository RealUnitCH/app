import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';

class ApiConfig {
  final NetworkMode networkMode;

  const ApiConfig({required this.networkMode});

  String get apiHost => networkMode.isTestnet ? 'dev.api.dfx.swiss' : 'api.dfx.swiss';

  Asset get asset => networkMode.isTestnet ? realUnitTestAsset : realUnitAsset;
}
