import 'package:realunit_wallet/models/asset.dart';

class PricePoint {
  final Asset asset;
  final BigInt price;
  final DateTime time;

  const PricePoint({
    required this.asset,
    required this.price,
    required this.time,
  });
}
