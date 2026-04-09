import 'package:realunit_wallet/packages/wallet/transaction_priority.dart';
import 'package:erc20/erc20.dart';
import 'package:web3dart/web3dart.dart';

Future<Future<String> Function()> createERC20Transaction(
  Web3Client client, {
  required Credentials currentAccount,
  required String receiveAddress,
  required BigInt amount,
  required String contractAddress,
  required int chainId,
  required TransactionPriority priority,
}) async {
  final transaction = Transaction(
    from: currentAccount.address,
    to: EthereumAddress.fromHex(contractAddress),
    maxPriorityFeePerGas:
        chainId == 1 ? EtherAmount.fromInt(EtherUnit.gwei, priority.tip) : null,
    value: EtherAmount.zero(),
  );

  final erc20 = ERC20(
    client: client,
    address: EthereumAddress.fromHex(contractAddress),
    chainId: chainId,
  );

  return () => erc20.transfer(
        EthereumAddress.fromHex(receiveAddress),
        amount,
        credentials: currentAccount,
        transaction: transaction,
      );
}

