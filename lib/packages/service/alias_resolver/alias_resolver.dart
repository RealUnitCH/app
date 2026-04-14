import 'openalias_resolver.dart';

export 'openalias_resolver.dart';

abstract class AliasResolver {
  Future<AliasRecord?> lookupAlias(String alias, String ticker,
      [String? tickerFallback]);

  static Future<AliasRecord?> resolve({
    required String alias,
    required String ticker,
    String? tickerFallback,
  }) async {
    List<AliasResolver> all = [OpenAliasResolver()];
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

  AliasRecord({
    required this.address,
    required this.name,
  });
}
