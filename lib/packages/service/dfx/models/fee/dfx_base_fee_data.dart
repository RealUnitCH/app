abstract class DfxBaseFeeData {
  final double rate; // final fee rate
  final double fixed; // final fixed fee
  final double network; // final network fee

  const DfxBaseFeeData({
    required this.rate,
    required this.fixed,
    required this.network,
  });
}
