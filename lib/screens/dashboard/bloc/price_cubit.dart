import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/models/asset.dart';
import 'package:realunit_wallet/packages/service/price_service.dart';
import 'package:realunit_wallet/styles/currency.dart';

class PriceCubit extends Cubit<BigInt> {
  PriceCubit(this._service, {required this.asset, required this.currency})
      : super(BigInt.zero) {
    _service.getPriceOfAsset(asset, currency).then(emit);
  }

  final APriceService _service;
  final Asset asset;
  final Currency currency;
}
