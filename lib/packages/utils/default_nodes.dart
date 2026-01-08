import 'package:realunit_wallet/models/node.dart';

const defaultNodes = [
  Node(chainId: 1, name: 'Ethereum', httpsUrl: 'https://eth-mainnet.g.alchemy.com/v2/9qEJRkxr1gAyFfwsCU6qODRSqj3TAzjj',),
  Node(chainId: 11155111, name: 'Sepolia', httpsUrl: 'https://eth-sepolia.g.alchemy.com/v2/9qEJRkxr1gAyFfwsCU6qODRSqj3TAzjj',),
  Node(chainId: 137, name: 'Polygon', httpsUrl: 'https://polygon-mainnet.g.alchemy.com/v2/9qEJRkxr1gAyFfwsCU6qODRSqj3TAzjj',),
  Node(chainId: 8453, name: 'Base', httpsUrl: 'https://base-mainnet.g.alchemy.com/v2/9qEJRkxr1gAyFfwsCU6qODRSqj3TAzjj',),
  Node(chainId: 10, name: 'Optimism', httpsUrl: 'https://opt-mainnet.g.alchemy.com/v2/9qEJRkxr1gAyFfwsCU6qODRSqj3TAzjj',),
  Node(chainId: 42161, name: 'Arbitrum', httpsUrl: 'https://arb-mainnet.g.alchemy.com/v2/9qEJRkxr1gAyFfwsCU6qODRSqj3TAzjj',),
];
