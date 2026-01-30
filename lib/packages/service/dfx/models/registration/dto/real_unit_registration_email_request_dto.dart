class RealUnitEmailRegistrationRequestDto {
  final String email;
  final String walletAddress;

  const RealUnitEmailRegistrationRequestDto({
    required this.email,
    required this.walletAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'walletAddress': walletAddress,
    };
  }
}
