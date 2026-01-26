class RealUnitEmailRegistrationRequestDto {
  final String email;

  const RealUnitEmailRegistrationRequestDto({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
    };
  }
}
