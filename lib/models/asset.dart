import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/utils/fast_hash.dart';

class Asset {
  static int getId(int chainId, String address) =>
      fastHash("$chainId:$address");

  int get id => getId(chainId, address);

  final int chainId;
  final String address;
  final String name;
  final String symbol;
  final int decimals;

  const Asset({
    required this.chainId,
    required this.address,
    required this.name,
    required this.symbol,
    required this.decimals,
  });

  Balance getEmptyBalance(String wallet) => Balance(
        chainId: chainId,
        contractAddress: address,
        walletAddress: wallet,
        balance: BigInt.zero,
        asset: this,
      );
}
