import 'package:graphql/client.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/ponder/models/ponder_tx.dart';
import 'package:realunit_wallet/packages/ponder/models/savings_saved.dart';
import 'package:realunit_wallet/packages/ponder/models/savings_withdrawn.dart';

class Ponder {
  final GraphQLClient client = GraphQLClient(
    cache: GraphQLCache(),
    link: HttpLink(
      'https://ponder.deuro.com',
    ),
  );

  Future<List<Transaction>> getSavingsSavedTransactions(String address) async {
    final QueryOptions options = QueryOptions(
      document: gql(
        '''
        query SavingsSaved {
          savingsSaveds(
            orderBy: "blockheight", 
            orderDirection: "desc", 
            where: { account: "${address.toLowerCase()}" }
          ) {
            items {
                created
                blockheight
                txHash
                account
                amount
              }
          }
        }
      ''',
      ),
      parserFn: (data) => SavingsSaved.fromJson(data),
    );

    return _queryTransaction<SavingsSaved>(options, address);
  }

  Future<List<Transaction>> getSavingsWithdrawnTransactions(String address) async {
    final QueryOptions options = QueryOptions(
      document: gql(
        '''
        query SavingsWithdrawn {
					savingsWithdrawns(
						orderBy: "blockheight"
						orderDirection: "desc"
						where: { account: "${address.toLowerCase()}" }
					) {
            items {
                created
                blockheight
                txHash
                account
                amount
              }
          }
        }
      ''',
      ),
      parserFn: (data) => SavingsWithdrawn.fromJson(data),
    );

    return _queryTransaction<SavingsWithdrawn>(options, address);
  }

  Future<List<Transaction>> _queryTransaction<T extends PonderTx>(
      QueryOptions options, String address) async {
    // ignore: unused_local_variable
    final QueryResult result = await client.query(options);

    return [];
  }
}
