import 'package:realunit_wallet/packages/config/network_mode.dart';

class ApiConfig {
  final NetworkMode networkMode;

  const ApiConfig({required this.networkMode});

  String get apiHost => networkMode.isTestnet ? 'dev.api.dfx.swiss' : 'api.dfx.swiss';
}
