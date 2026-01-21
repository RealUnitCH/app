class TransactionDto {
  final int? id;
  final int? rate;
  final String? inputTxId;
  final String? outputTxId;

  const TransactionDto({
    this.id,
    this.rate,
    this.inputTxId,
    this.outputTxId,
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) {
    return TransactionDto(
      id: json['id'] as int?,
      rate: json['rate'] as int?,
      inputTxId: json['inputTxId'] as String?,
      outputTxId: json['outputTxId'] as String?,
    );
  }
}
