enum RegistrationEmailStatus {
  emailRegistered,
  mergeRequested,
  verificationCodeSent;

  static RegistrationEmailStatus fromString(String status) {
    switch (status) {
      case 'email_registered':
        return RegistrationEmailStatus.emailRegistered;
      case 'merge_requested':
        return RegistrationEmailStatus.mergeRequested;
      case 'verification_code_sent':
        return RegistrationEmailStatus.verificationCodeSent;
      default:
        throw Exception('Unknown registration status: $status');
    }
  }
}
