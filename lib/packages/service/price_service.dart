import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/models/price_point.dart';
import 'package:realunit_wallet/styles/currency.dart';

abstract class APriceService {
  Future<BigInt> getPriceOfAsset(Asset asset, Currency currency);

  Future<List<PricePoint>> getPriceChart(Asset asset, Currency currency);
}
