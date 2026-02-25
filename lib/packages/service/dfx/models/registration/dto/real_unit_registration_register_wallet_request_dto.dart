class RealUnitRegisterWalletRequestDto {
  final String walletAddress;
  final String signature;
  final String registrationDate;

  const RealUnitRegisterWalletRequestDto({
    required this.walletAddress,
    required this.signature,
    required this.registrationDate,
  });

  Map<String, dynamic> toJson() => {
    'walletAddress': walletAddress,
    'signature': signature,
    'registrationDate': registrationDate,
  };
}
