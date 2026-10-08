/// Request body for `PUT /v1/realunit/transfer/hardware`. REALU has
/// `decimals = 0`, so [amount] is a whole number of shares.
class RealUnitHardwareTransferRequestDto {
  final String toAddress;
  final int amount;

  const RealUnitHardwareTransferRequestDto({
    required this.toAddress,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'toAddress': toAddress,
      'amount': amount,
    };
  }
}

/// Response of `PUT /v1/realunit/transfer/hardware` — the unsigned EIP-1559
/// transaction the BitBox must sign. There is no REALU network fee; ETH pays
/// gas.
class RealUnitHardwareTransferPaymentInfoDto {
  final String unsignedTx;
  final String toAddress;
  final int amount;

  const RealUnitHardwareTransferPaymentInfoDto({
    required this.unsignedTx,
    required this.toAddress,
    required this.amount,
  });

  factory RealUnitHardwareTransferPaymentInfoDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return RealUnitHardwareTransferPaymentInfoDto(
      unsignedTx: json['unsignedTx'] as String,
      toAddress: json['toAddress'] as String,
      amount: (json['amount'] as num).toInt(),
    );
  }
}
