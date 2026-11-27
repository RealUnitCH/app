class RealUnitVerifyEmailRequestDto {
  final String token;

  const RealUnitVerifyEmailRequestDto({
    required this.token,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }
}
