import 'package:realunit_wallet/packages/service/alias_resolver/ens_resolver.dart';
import 'package:web3dart/web3dart.dart';

import 'openalias_resolver.dart';

export 'openalias_resolver.dart';

abstract class AliasResolver {
  Future<AliasRecord?> lookupAlias(String alias, String ticker,
      [String? tickerFallback]);

  static Future<AliasRecord?> resolve(
    Web3Client client, {
    required String alias,
    required String ticker,
    String? tickerFallback,
  }) async {
    List<AliasResolver> all = [EnsResolver(client), OpenAliasResolver()];
    for (final resolver in all) {
      final result = await resolver.lookupAlias(alias, ticker, tickerFallback);
      if (result != null) return result;
    }
    return null;
  }
}

class AliasRecord {
  final String address;
  final String name;
  final String description;

  AliasRecord({
    required this.address,
    required this.name,
    required this.description,
  });
}
