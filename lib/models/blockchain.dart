import 'package:realunit_wallet/models/asset.dart';

enum Blockchain {
  ethereum(1, "Ethereum", "ETH"),
  polygon(137, "Polygon", "POL"),
  base(8453, "Base", "ETH"),
  optimism(10, "Optimism", "ETH"),
  arbitrum(42161, "Arbitrum", "ETH");

  const Blockchain(this.chainId, this.name, this.nativeSymbol);

  static Blockchain getFromChainId(int chainId) =>
      Blockchain.values.firstWhere((e) => e.chainId == chainId);

  final int chainId;
  final String nativeSymbol;
  final String name;

  Asset get nativeAsset => Asset(
        chainId: chainId,
        address: "0x0",
        name: name,
        symbol: nativeSymbol,
        decimals: 18,
      );
}
