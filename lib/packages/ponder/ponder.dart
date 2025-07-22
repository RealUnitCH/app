import 'package:deuro_wallet/models/transaction.dart';
import 'package:deuro_wallet/packages/contracts/contracts.dart';
import 'package:deuro_wallet/packages/ponder/models/ponder_tx.dart';
import 'package:deuro_wallet/packages/ponder/models/savings_saved.dart';
import 'package:deuro_wallet/packages/ponder/models/savings_withdrawn.dart';
import 'package:deuro_wallet/packages/utils/default_assets.dart';
import 'package:graphql/client.dart';

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

  Future<List<Transaction>> getSavingsWithdrawnTransactions(
      String address) async {
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
    final QueryResult result = await client.query(options);

    final txList = <Transaction>[];
    for (final item in result.parsedData as List<T>) {
      txList.add(Transaction(
        height: item.blockheight.toInt(),
        txId: item.txHash,
        chainId: 1,
        senderAddress: address,
        receiverAddress: savingsGatewayAddress,
        amount: item.amount,
        asset: dEUROAsset,
        type: item.txType,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(item.created.toInt() * 1000),
        note: null,
        data: null,
      ));
    }

    return txList;
  }
}
