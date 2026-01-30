enum RegistrationStatus {
  completed,
  pendingReview,
  forwardingFailed;

  static RegistrationStatus fromString(String status) {
    switch (status) {
      case 'completed':
        return RegistrationStatus.completed;
      case 'pending_review':
        return RegistrationStatus.pendingReview;
      case 'forwarding_failed':
        return RegistrationStatus.forwardingFailed;
      default:
        throw Exception('Unknown registration status: $status');
    }
  }
}
