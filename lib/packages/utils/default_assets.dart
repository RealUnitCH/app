import 'package:realunit_wallet/models/asset.dart';

const ethereumEthAssetId = 111;
const sepoliaEthAssetId = 392;

const realUnitAsset = Asset(
  chainId: 1,
  address: '0x553C7f9C780316FC1D34b8e14ac2465Ab22a090B',
  name: 'RealUnit Token',
  symbol: 'REALU',
  decimals: 0,
);
const realUnitTestAsset = Asset(
  chainId: 11155111,
  address: '0x0add9824820508dd7992cbebb9f13fbe8e45a30f',
  name: 'RealUnit Token (Sepolia)',
  symbol: 'REALU',
  decimals: 0,
);
