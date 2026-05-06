class BroadcastTransactionResponseDto {
  final String txHash;

  const BroadcastTransactionResponseDto({required this.txHash});

  factory BroadcastTransactionResponseDto.fromJson(Map<String, dynamic> json) {
    return BroadcastTransactionResponseDto(
      txHash: json['txHash'] as String,
    );
  }
}
