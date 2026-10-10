class RealUnitAccountBalanceDto {
  final String? balance;

  const RealUnitAccountBalanceDto({required this.balance});

  factory RealUnitAccountBalanceDto.fromJson(Map<String, dynamic> json) {
    return RealUnitAccountBalanceDto(balance: json['balance'] as String?);
  }
}
