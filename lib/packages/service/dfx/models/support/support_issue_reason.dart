enum SupportIssueReason {
  other('Other'),
  fundsNotReceived('FundsNotReceived'),
  transactionMissing('TransactionMissing'),
  rejectCall('RejectCall'),
  repeatCall('RepeatCall'),
  civilStatusChanged('CivilStatusChanged');

  final String value;

  const SupportIssueReason(this.value);

  static SupportIssueReason fromJson(String json) {
    return SupportIssueReason.values.firstWhere(
      (e) => e.value == json,
      orElse: () => SupportIssueReason.other,
    );
  }

  String toJson() => value;
}
