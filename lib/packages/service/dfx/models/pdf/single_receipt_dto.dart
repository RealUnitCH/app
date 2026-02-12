class SingleReceiptDto {
  final int transactionId;

  const SingleReceiptDto({
    required this.transactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
    };
  }
}
