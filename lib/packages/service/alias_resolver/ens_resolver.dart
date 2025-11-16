import 'package:realunit_wallet/packages/wallet/ens_lookup.dart';
import 'package:web3dart/web3dart.dart';

import 'alias_resolver.dart';

class EnsResolver extends AliasResolver {
  EnsResolver(Web3Client client) : _ensLookup = EnsLookup.create(client);

  final EnsLookup _ensLookup;

  @override
  Future<AliasRecord?> lookupAlias(String alias, String ticker,
      [String? tickerFallback]) async {
    final address = await _ensLookup.resolveName(alias);

    if (address != null) {
      return AliasRecord(address: address, name: alias, description: '');
    }
    return null;
  }
}
