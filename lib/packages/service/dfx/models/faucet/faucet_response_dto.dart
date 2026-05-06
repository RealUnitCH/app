class FaucetResponseDto {
  final String txId;
  final double amount;

  const FaucetResponseDto({required this.txId, required this.amount});

  factory FaucetResponseDto.fromJson(Map<String, dynamic> json) {
    return FaucetResponseDto(
      txId: json['txId'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}
