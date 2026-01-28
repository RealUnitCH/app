enum RegistrationStatus {
  completed,
  pendingReview,
  manualReviewDataMismatch,
  forwardingFailed;

  static RegistrationStatus fromString(String status) {
    switch (status) {
      case 'completed':
        return RegistrationStatus.completed;
      case 'pending_review':
        return RegistrationStatus.pendingReview;
      case 'manual_review_data_mismatch':
        return RegistrationStatus.manualReviewDataMismatch;
      case 'forwarding_failed':
        return RegistrationStatus.forwardingFailed;
      default:
        throw Exception('Unknown registration status: $status');
    }
  }
}
