import 'package:deuro_wallet/models/transaction.dart';
import 'package:deuro_wallet/packages/contracts/contracts.dart';
import 'package:deuro_wallet/packages/ponder/models/savings_saved.dart';
import 'package:deuro_wallet/packages/utils/default_assets.dart';
import 'package:graphql/client.dart';

class Ponder {
  final GraphQLClient client = GraphQLClient(
    cache: GraphQLCache(),
    link: HttpLink(
      'https://ponder.deuro.com',
    ),
  );

  Future<List<Transaction>> getSavingsSavingsTransactions(String address) async {
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

    final QueryResult result = await client.query(options);

    final txList = <Transaction>[];
    for (final item in result.parsedData as List<SavingsSaved>) {
      txList.add(Transaction(
        height: item.blockheight.toInt(),
        txId: item.txHash,
        chainId: 1,
        senderAddress: address,
        receiverAddress: savingsGatewayAddress,
        amount: item.amount,
        asset: dEUROAsset,
        type: TransactionTypes.savingsAdd,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(item.created.toInt() * 1000),
        note: null,
        data: null,
      ));
    }

    return txList;
  }
}
