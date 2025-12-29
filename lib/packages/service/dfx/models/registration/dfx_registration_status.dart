enum DfxRegistrationStatus {
  completed,
  pendingReview;

  static DfxRegistrationStatus fromString(String status) {
    switch (status) {
      case 'completed':
        return DfxRegistrationStatus.completed;
      case 'pending_review':
        return DfxRegistrationStatus.pendingReview;
      default:
        throw Exception('Unknown registration status: $status');
    }
  }
}
