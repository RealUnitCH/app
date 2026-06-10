import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/config/network_mode.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';

/// `true` when compiled with `--dart-define=MAESTRO_MOCK=true` so the app
/// routes all DFX API calls through the in-process [MaestroMockClient].
/// In production this is always `false`.
bool get _localTesting => const bool.fromEnvironment('MAESTRO_MOCK', defaultValue: false);

class ApiConfig {
  final NetworkMode networkMode;

  const ApiConfig({required this.networkMode});

  String get apiHost => _localTesting
      ? 'localhost:3000'
      : networkMode.isTestnet
      ? 'dev.api.dfx.swiss'
      : 'api.dfx.swiss';

  Asset get asset => networkMode.isTestnet ? realUnitTestAsset : realUnitAsset;

  int get ethAssetId => networkMode.isTestnet ? sepoliaEthAssetId : ethereumEthAssetId;
  int get zchfAssetId => networkMode.isTestnet ? sepoliaZchfAssetId : ethereumZchfAssetId;
}

Uri buildUri(
  String authority,
  String path, [
  Map<String, dynamic>? queryParams,
]) {
  // `_localTesting` is a file-private dev hint that is always `false` in the
  // shipped source. The `Uri.http(...)` branch only fires when a developer
  // flips the constant locally to point the app at a local backend — it is
  // not reachable from any production or test path, so line-coverage cannot
  // mark it as executed.
  return _localTesting
      ? Uri.http(authority, path, queryParams) // coverage:ignore-line
      : Uri.https(authority, path, queryParams);
}
