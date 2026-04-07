enum SupportIssueState {
  created('Created'),
  pending('Pending'),
  completed('Completed'),
  canceled('Canceled');

  final String value;

  const SupportIssueState(this.value);

  static SupportIssueState fromJson(String json) {
    return SupportIssueState.values.firstWhere(
      (e) => e.value == json,
      orElse: () => SupportIssueState.created,
    );
  }

  String toJson() => value;
}
