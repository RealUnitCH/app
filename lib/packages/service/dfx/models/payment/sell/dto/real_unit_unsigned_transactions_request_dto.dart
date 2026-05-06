class RealUnitUnsignedTransactionsRequestDto {
  final String swap;
  final String deposit;

  const RealUnitUnsignedTransactionsRequestDto({required this.swap, required this.deposit});

  factory RealUnitUnsignedTransactionsRequestDto.fromJson(Map<String, dynamic> json) {
    return RealUnitUnsignedTransactionsRequestDto(
      swap: json['swap'] as String,
      deposit: json['deposit'] as String,
    );
  }
}
