import 'package:realunit_wallet/packages/service/dfx/models/fee/dfx_base_fee_data.dart';

class DfxSwapFeeData extends DfxBaseFeeData {
  final double min;
  final double dfx;
  final double total;

  const DfxSwapFeeData({
    required super.rate,
    required super.fixed,
    required super.network,
    required this.min,
    required this.dfx,
    required this.total,
  });

  factory DfxSwapFeeData.fromJson(Map<String, dynamic> json) {
    return DfxSwapFeeData(
      rate: (json['rate'] as num).toDouble(),
      fixed: (json['fixed'] as num).toDouble(),
      network: (json['network'] as num).toDouble(),
      min: (json['min'] as num).toDouble(),
      dfx: (json['dfx'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}
