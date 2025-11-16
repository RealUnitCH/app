import 'package:realunit_wallet/models/blockchain.dart';

String getBlockExplorerUrl(Blockchain blockchain) {
  switch (blockchain) {
    case Blockchain.ethereum:
      return 'https://etherscan.io';
    case Blockchain.polygon:
      return 'https://polygonscan.com';
    case Blockchain.arbitrum:
      return 'https://arbiscan.io';
    case Blockchain.optimism:
      return 'https://optimistic.etherscan.io';
    case Blockchain.base:
      return 'https://basescan.org';
  }
}
