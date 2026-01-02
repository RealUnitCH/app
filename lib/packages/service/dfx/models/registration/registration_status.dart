enum RegistrationStatus {
  completed,
  pendingReview;

  static RegistrationStatus fromString(String status) {
    switch (status) {
      case 'completed':
        return RegistrationStatus.completed;
      case 'pending_review':
        return RegistrationStatus.pendingReview;
      default:
        throw Exception('Unknown registration status: $status');
    }
  }
}
