enum SupportIssueType {
  genericIssue('GenericIssue'),
  transactionIssue('TransactionIssue'),
  kycIssue('KycIssue'),
  limitRequest('LimitRequest'),
  partnershipRequest('PartnershipRequest'),
  notificationOfChanges('NotificationOfChanges'),
  bugReport('BugReport'),
  verificationCall('VerificationCall');

  final String value;

  const SupportIssueType(this.value);

  static SupportIssueType fromJson(String json) {
    return SupportIssueType.values.firstWhere(
      (e) => e.value == json,
      orElse: () => SupportIssueType.genericIssue,
    );
  }

  String toJson() => value;
}
