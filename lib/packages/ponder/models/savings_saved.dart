class SavingsSaved {
  final BigInt created;
  final BigInt blockheight;
  final String txHash;
  final String account;
  final BigInt amount;

  const SavingsSaved({
    required this.created,
    required this.blockheight,
    required this.txHash,
    required this.account,
    required this.amount,
});

  static List<SavingsSaved> fromJson(Map<String, dynamic> query) {
    final result = <SavingsSaved>[];
    final items = query['savingsSaveds']['items'] as List<dynamic>;

    for (final itemRaw in items) {
      final item = itemRaw as Map<String, dynamic>;
      result.add(SavingsSaved(
          created: BigInt.parse(item['created']),
          blockheight: BigInt.parse(item['blockheight']),
          txHash: item['txHash'],
          account: item['account'],
          amount: BigInt.parse(item['amount']),
      ));
    }

    return result;
  }
}
