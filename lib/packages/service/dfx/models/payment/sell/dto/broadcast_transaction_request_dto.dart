class BroadcastTransactionRequestDto {
  final String unsignedTx;
  final String r;
  final String s;
  final int v;

  const BroadcastTransactionRequestDto({
    required this.unsignedTx,
    required this.r,
    required this.s,
    required this.v,
  });

  Map<String, dynamic> toJson() {
    return {
      'unsignedTx': unsignedTx,
      'r': r,
      's': s,
      'v': v,
    };
  }
}
