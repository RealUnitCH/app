class DfxFeesData {
  final double rate;
  final double fixed;
  final double network;
  final double min;
  final double dfx;
  final double total;

  const DfxFeesData({
    required this.rate,
    required this.fixed,
    required this.network,
    required this.min,
    required this.dfx,
    required this.total,
  });

  factory DfxFeesData.fromJson(Map<String, dynamic> json) {
    return DfxFeesData(
      rate: (json['rate'] as num).toDouble(),
      fixed: (json['fixed'] as num).toDouble(),
      network: (json['network'] as num).toDouble(),
      min: (json['min'] as num).toDouble(),
      dfx: (json['dfx'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}
