import 'package:realunit_wallet/models/asset.dart';

const dEUROAsset = Asset(chainId: 1, address: '0xbA3f535bbCcCcA2A154b573Ca6c5A49BAAE0a3ea', name: 'dEuro', symbol: 'dEURO', decimals: 18);
const dEUROBaseAsset = Asset(chainId: 8453, address: '0x1B5F7fA46ED0F487F049C42f374cA4827d65A264', name: 'dEuro (Base)', symbol: 'dEURO', decimals: 18);
const dEUROOptimismAsset = Asset(chainId: 10, address: '0x1B5F7fA46ED0F487F049C42f374cA4827d65A264', name: 'dEuro (Optimism)', symbol: 'dEURO', decimals: 18);
const dEUROArbitrumAsset = Asset(chainId: 42161, address: '0x5e85fAf503621830CA857a5f38B982E0cc57D537', name: 'dEuro (Arbitrum)', symbol: 'dEURO', decimals: 18);
const dEUROPolygonAsset = Asset(chainId: 137, address: '0xC2ff25dD99e467d2589b2c26EDd270F220F14E47', name: 'dEuro (Polygon)', symbol: 'dEURO', decimals: 18);
const nDEPSAsset = Asset(chainId: 1, address: '0xc71104001A3CCDA1BEf1177d765831Bd1bfE8eE6', name: 'Native dEuro Protocol Share', symbol: 'nDEPS', decimals: 18);
const depsAsset = Asset(chainId: 1, address: '0x103747924E74708139a9400e4Ab4BEA79FFFA380', name: 'dEuro Protocol Share', symbol: 'DEPS', decimals: 18);

const defaultAssets = [
  // dEuro
  dEUROAsset,
  dEUROBaseAsset,
  dEUROOptimismAsset,
  dEUROArbitrumAsset,
  dEUROPolygonAsset,

  // DEPS
  nDEPSAsset,
  depsAsset,

  // Frankencoin
  Asset(chainId: 1, address: '0xB58E61C3098d85632Df34EecfB899A1Ed80921cB', name: 'Frankencoin', symbol: 'ZCHF', decimals: 18),
  Asset(chainId: 1, address: '0x1bA26788dfDe592fec8bcB0Eaff472a42BE341B2', name: 'Frankencoin Pool Share', symbol: 'FPS', decimals: 18),
  Asset(chainId: 1, address: '0x5052D3Cc819f53116641e89b96Ff4cD1EE80B182', name: 'Wrapped Frankencoin Pool Share', symbol: 'WFPS', decimals: 18),
  Asset(chainId: 137, address: '0x02567e4b14b25549331fCEe2B56c647A8bAB16FD', name: 'Frankencoin (Polygon)', symbol: 'ZCHF', decimals: 18),
  Asset(chainId: 137, address: '0x54Cc50D5CC4914F0c5DA8b0581938dC590d29b3D', name: 'Wrapped Frankencoin Pool Share (Polygon)', symbol: 'WFPS', decimals: 18),
  Asset(chainId: 8453, address: '0x20D1c515e38aE9c345836853E2af98455F919637', name: 'Frankencoin (Base)', symbol: 'ZCHF', decimals: 18),
  Asset(chainId: 10, address: '0x4F8a84C442F9675610c680990EdDb2CCDDB8aB6f', name: 'Frankencoin (Optimism)', symbol: 'ZCHF', decimals: 18),
  Asset(chainId: 42161, address: '0xB33c4255938de7A6ec1200d397B2b2F329397F9B', name: 'Frankencoin (Arbitrum)', symbol: 'ZCHF', decimals: 18),
];
