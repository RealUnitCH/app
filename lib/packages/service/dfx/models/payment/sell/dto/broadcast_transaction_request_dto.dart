class BroadcastTransactionRequestDto {
  final String signedTransaction;

  const BroadcastTransactionRequestDto({
    required this.signedTransaction,
  });

  Map<String, dynamic> toJson() {
    return {
      'signedTransaction': signedTransaction,
    };
  }
}
