import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';

/// if true, requires to have a local running backend
bool get _localTesting => true;

class ApiConfig {
  final NetworkMode networkMode;

  const ApiConfig({required this.networkMode});

  String get apiHost => _localTesting
      ? 'localhost:3000'
      : networkMode.isTestnet
          ? 'dev.api.dfx.swiss'
          : 'api.dfx.swiss';

  Asset get asset => networkMode.isTestnet ? realUnitTestAsset : realUnitAsset;
}

Uri buildUri(
  String authority,
  String path, [
  Map<String, dynamic>? queryParams,
]) {
  return _localTesting
      ? Uri.http(authority, path, queryParams)
      : Uri.https(authority, path, queryParams);
}
