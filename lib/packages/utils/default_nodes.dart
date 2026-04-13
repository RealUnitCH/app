import 'package:realunit_wallet/env/env.dart';
import 'package:realunit_wallet/models/node.dart';

final defaultNodes = [
  Node(
    chainId: 1,
    name: 'Ethereum',
    httpsUrl: 'https://eth-mainnet.g.alchemy.com/v2/${Env.alchemyApiKey}',
  ),
  Node(
    chainId: 11155111,
    name: 'Sepolia',
    httpsUrl: 'https://eth-sepolia.g.alchemy.com/v2/${Env.alchemyApiKey}',
  ),
];
