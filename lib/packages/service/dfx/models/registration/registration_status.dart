enum RegistrationStatus {
  completed,
  pendingReview,
  forwardingFailed,
  // Backend status when the wallet is already registered for the user.
  // The realunit-app used to handle this as a 400 BadRequestException
  // ("registration already exists") — PR DFXswiss/api#3733 makes the API
  // return this structured value instead, and the merge-confirmation /
  // retry code paths now branch on it as a soft success.
  alreadyRegistered;

  static RegistrationStatus fromString(String status) {
    switch (status) {
      case 'completed':
        return RegistrationStatus.completed;
      case 'pending_review':
        return RegistrationStatus.pendingReview;
      case 'forwarding_failed':
        return RegistrationStatus.forwardingFailed;
      case 'already_registered':
        return RegistrationStatus.alreadyRegistered;
      default:
        throw Exception('Unknown registration status: $status');
    }
  }
}
