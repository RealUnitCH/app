class MultiReceiptDto {
  final List<int> transactionIds;

  const MultiReceiptDto({
    required this.transactionIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'transactionIds': transactionIds,
    };
  }
}
