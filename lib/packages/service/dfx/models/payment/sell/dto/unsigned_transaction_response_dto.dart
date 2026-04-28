class UnsignedTransactionResponseDto {
  final String rawTransaction;

  const UnsignedTransactionResponseDto({required this.rawTransaction});

  factory UnsignedTransactionResponseDto.fromJson(Map<String, dynamic> json) {
    return UnsignedTransactionResponseDto(
      rawTransaction: json['rawTransaction'] as String,
    );
  }
}
