import 'package:realunit_wallet/models/blockchain.dart';

String getBlockExplorerUrl(Blockchain blockchain) {
  switch (blockchain) {
    case Blockchain.ethereum:
      return 'https://etherscan.io';
    case Blockchain.sepolia:
      return 'https://sepolia.etherscan.io';
  }
}
