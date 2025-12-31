import 'package:realunit_wallet/packages/service/dfx/models/fee/dfx_base_fee_data.dart';

class DfxBuyFeeData extends DfxBaseFeeData {
  final double min;
  final double dfx;
  final double bank;
  final double total;
  final double? networkStart;

  const DfxBuyFeeData({
    required super.rate,
    required super.fixed,
    required super.network,
    required this.min,
    required this.dfx,
    required this.bank,
    required this.total,
    this.networkStart,
  });

  factory DfxBuyFeeData.fromJson(Map<String, dynamic> json) {
    return DfxBuyFeeData(
      rate: (json['rate'] as num).toDouble(),
      fixed: (json['fixed'] as num).toDouble(),
      network: (json['network'] as num).toDouble(),
      min: (json['min'] as num).toDouble(),
      dfx: (json['dfx'] as num).toDouble(),
      bank: (json['bank'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      networkStart: json['networkStart'] != null ? (json['networkStart'] as num).toDouble() : null,
    );
  }
}
