import 'package:realunit_wallet/models/asset.dart';

const realUnitAsset = Asset(chainId: 1, address: '0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B', name: 'RealUnit Token', symbol: 'REALU', decimals: 0);
const realUnitTestAsset = Asset(chainId: 11155111, address: '0x0add9824820508dd7992cbebb9f13fbe8e45a30f', name: 'RealUnit Token (Sepolia)', symbol: 'REALU', decimals: 0);
const dEUROAsset = Asset(chainId: 1, address: '0xbA3f535bbCcCcA2A154b573Ca6c5A49BAAE0a3ea', name: 'dEuro', symbol: 'dEURO', decimals: 18);

const defaultAssets = [
  realUnitAsset,
  realUnitTestAsset,
  dEUROAsset,

  // Frankencoin
  Asset(chainId: 1, address: '0xB58E61C3098d85632Df34EecfB899A1Ed80921cB', name: 'Frankencoin', symbol: 'ZCHF', decimals: 18),
  Asset(chainId: 1, address: '0x1bA26788dfDe592fec8bcB0Eaff472a42BE341B2', name: 'Frankencoin Pool Share', symbol: 'FPS', decimals: 18),
  Asset(chainId: 1, address: '0x5052D3Cc819f53116641e89b96Ff4cD1EE80B182', name: 'Wrapped Frankencoin Pool Share', symbol: 'WFPS', decimals: 18),
];
