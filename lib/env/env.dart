import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'ALCHEMY_API_KEY', obfuscate: true)
  static final String alchemyApiKey = _Env.alchemyApiKey;

  @EnviedField(varName: 'ETHERSCAN_API_KEY', obfuscate: true)
  static final String etherscanApiKey = _Env.etherscanApiKey;
}
