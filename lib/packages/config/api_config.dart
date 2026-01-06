import 'package:realunit_wallet/packages/config/network_mode.dart';

class ApiConfig {
  final NetworkMode networkMode;

  const ApiConfig({required this.networkMode});

  /// Base URL for DFX API (without protocol)
  String get apiHost => networkMode.isTestnet ? 'dev.api.dfx.swiss' : 'api.dfx.swiss';

  /// Base URL for DFX App/Frontend (without protocol)
  String get appHost => networkMode.isTestnet ? 'dev.app.dfx.swiss' : 'app.dfx.swiss';
}
