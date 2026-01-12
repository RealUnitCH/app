import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/blockchain.dart';

String getAssetImagePath(Asset asset) {
  switch ('${asset.chainId}:${asset.address.toLowerCase()}') {
    case '1:0x0':
    case '8453:0x0':
    case '10:0x0':
    case '42161:0x0':
      return 'assets/images/coins/ETH.png';
    case '137:0x0':
      return 'assets/images/coins/polygon.png';
    case '1:0xba3f535bbcccca2a154b573ca6c5a49baae0a3ea':
      return 'assets/images/coins/dEuro.png';
    case '1:0x103747924e74708139a9400e4ab4bea79fffa380':
      return 'assets/images/coins/DEPS.png';
    case '1:0xc71104001a3ccda1bef1177d765831bd1bfe8ee6':
      return 'assets/images/coins/nDEPS.png';
    case '1:0x553c7f9c780316fc1d34b8e14ac2465ab22a090b':
    case '11155111:0x0add9824820508dd7992cbebb9f13fbe8e45a30f':
      return 'assets/images/coins/REALU.png';

    case '1:0xb58e61c3098d85632df34eecfb899a1ed80921cb':
    case '137:0x02567e4b14b25549331fcee2b56c647a8bab16fd':
    case '8453:0x20d1c515e38ae9c345836853e2af98455f919637':
    case '10:0x4f8a84c442f9675610c680990eddb2ccddb8ab6f':
    case '42161:0xb33c4255938de7a6ec1200d397b2b2f329397f9b':
      return 'assets/images/coins/ZCHF.png';
    case '1:0x1ba26788dfde592fec8bcb0eaff472a42be341b2':
    case '1:0x5052d3cc819f53116641e89b96ff4cd1ee80b182':
    case '137:0x54cc50d5cc4914f0c5da8b0581938dc590d29b3d':
      return 'assets/images/coins/FPS.png';
    default:
      return 'assets/images/coins/dEuro.png';
  }
}

String getChainImagePath(int chainId) {
  switch (Blockchain.getFromChainId(chainId)) {
    case Blockchain.ethereum:
      return 'assets/images/coins/ETH.png';
    case Blockchain.sepolia:
      return 'assets/images/coins/ETH.png';
    case Blockchain.polygon:
      return 'assets/images/coins/polygon.png';
    case Blockchain.base:
      return 'assets/images/coins/base.png';
    case Blockchain.optimism:
      return 'assets/images/coins/optimism.png';
    case Blockchain.arbitrum:
      return 'assets/images/coins/arbitrum.png';
  }
}
