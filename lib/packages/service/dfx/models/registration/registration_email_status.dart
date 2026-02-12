enum RegistrationEmailStatus {
  emailRegistered,
  mergeRequested;

  static RegistrationEmailStatus fromString(String status) {
    switch (status) {
      case 'email_registered':
        return RegistrationEmailStatus.emailRegistered;
      case 'merge_requested':
        return RegistrationEmailStatus.mergeRequested;
      default:
        throw Exception('Unknown registration status: $status');
    }
  }
}
