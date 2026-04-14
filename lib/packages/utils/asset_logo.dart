import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/blockchain.dart';

String getAssetImagePath(Asset asset) {
  switch ('${asset.chainId}:${asset.address.toLowerCase()}') {
    case '1:0x0':
      return 'assets/images/coins/ETH.png';
    case '1:0x553c7f9c780316fc1d34b8e14ac2465ab22a090b':
    case '11155111:0x0add9824820508dd7992cbebb9f13fbe8e45a30f':
      return 'assets/images/coins/REALU.png';
    default:
      return 'assets/images/coins/REALU.png';
  }
}

String getChainImagePath(int chainId) {
  switch (Blockchain.getFromChainId(chainId)) {
    case Blockchain.ethereum:
      return 'assets/images/coins/ETH.png';
    case Blockchain.sepolia:
      return 'assets/images/coins/ETH.png';
  }
}
