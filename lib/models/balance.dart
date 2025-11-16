import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/utils/fast_hash.dart';

class Balance {
  int get id => fastHash("$walletAddress:$chainId:$contractAddress");

  final int chainId;
  final String contractAddress;
  final String walletAddress;
  BigInt balance;
  final Asset asset;

  Balance({
    required this.chainId,
    required this.contractAddress,
    required this.walletAddress,
    required this.balance,
    required this.asset,
  });

  @override
  int get hashCode => Object.hash(chainId, contractAddress, walletAddress);

  @override
  bool operator ==(Object other) =>
      other is Balance &&
      chainId == other.chainId &&
      contractAddress == other.contractAddress &&
      walletAddress == other.walletAddress;
}
