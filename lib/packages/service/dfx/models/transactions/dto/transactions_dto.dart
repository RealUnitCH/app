class TransactionDto {
  final int? id;
  final String? inputTxId;
  final String? outputTxId;

  const TransactionDto({
    this.id,
    this.inputTxId,
    this.outputTxId,
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) {
    return TransactionDto(
      id: json['id'] as int?,
      inputTxId: json['inputTxId'] as String?,
      outputTxId: json['outputTxId'] as String?,
    );
  }
}
