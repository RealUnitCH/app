import 'package:realunit_wallet/packages/service/dfx/models/fees/dfx_fees_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/price_step_dto.dart';
import 'package:realunit_wallet/styles/currency.dart';

class RealUnitSellPaymentInfoDto {
  final int id;
  final int routeId;
  final DateTime timestamp;
  final RealUnitEip7702DataDto eip7702;
  final String depositAddress;
  final double amount;
  final String tokenAddress;
  final int chainId;
  final DfxFeesData fees;
  final double minVolume;
  final double maxVolume;
  final double minVolumeTarget;
  final double maxVolumeTarget;
  final double exchangeRate;
  final double rate;
  final List<PriceStep> priceSteps;
  final double estimatedAmount;
  final Currency currency;
  final BeneficiaryDto beneficiary;
  final bool isValid;

  const RealUnitSellPaymentInfoDto({
    required this.id,
    required this.routeId,
    required this.timestamp,
    required this.eip7702,
    required this.depositAddress,
    required this.amount,
    required this.tokenAddress,
    required this.chainId,
    required this.fees,
    required this.minVolume,
    required this.maxVolume,
    required this.minVolumeTarget,
    required this.maxVolumeTarget,
    required this.exchangeRate,
    required this.rate,
    required this.priceSteps,
    required this.estimatedAmount,
    required this.currency,
    required this.beneficiary,
    required this.isValid,
  });

  factory RealUnitSellPaymentInfoDto.fromJson(Map<String, dynamic> json) {
    return RealUnitSellPaymentInfoDto(
      id: json['id'] as int,
      routeId: json['routeId'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      eip7702: RealUnitEip7702DataDto.fromJson(json['eip7702'] as Map<String, dynamic>),
      depositAddress: json['depositAddress'] as String,
      amount: (json['amount'] as num).toDouble(),
      tokenAddress: json['tokenAddress'] as String,
      chainId: json['chainId'] as int,
      fees: DfxFeesData.fromJson(json['fees'] as Map<String, dynamic>),
      minVolume: (json['minVolume'] as num).toDouble(),
      maxVolume: (json['maxVolume'] as num).toDouble(),
      minVolumeTarget: (json['minVolumeTarget'] as num).toDouble(),
      maxVolumeTarget: (json['maxVolumeTarget'] as num).toDouble(),
      exchangeRate: (json['exchangeRate'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      priceSteps: (json['priceSteps'] as List<dynamic>)
          .map((e) => PriceStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedAmount: (json['estimatedAmount'] as num).toDouble(),
      currency: Currency.fromCode(json['currency'] as String),
      beneficiary: BeneficiaryDto.fromJson(json['beneficiary'] as Map<String, dynamic>),
      isValid: json['isValid'] as bool,
    );
  }
}

class BeneficiaryDto {
  final String? name;
  final String iban;

  const BeneficiaryDto({
    this.name,
    required this.iban,
  });

  factory BeneficiaryDto.fromJson(Map<String, dynamic> json) {
    return BeneficiaryDto(
      name: json['name'] as String?,
      iban: json['iban'] as String,
    );
  }
}

class Eip7702Domain {
  final String name;
  final String version;
  final int chainId;
  final String verifyingContract;

  const Eip7702Domain({
    required this.name,
    required this.version,
    required this.chainId,
    required this.verifyingContract,
  });

  factory Eip7702Domain.fromJson(Map<String, dynamic> json) {
    return Eip7702Domain(
      name: json['name'] as String,
      version: json['version'] as String,
      chainId: json['chainId'] as int,
      verifyingContract: json['verifyingContract'] as String,
    );
  }
}

class Eip7702TypeField {
  final String name;
  final String type;

  const Eip7702TypeField({
    required this.name,
    required this.type,
  });

  factory Eip7702TypeField.fromJson(Map<String, dynamic> json) {
    return Eip7702TypeField(
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }
}

class Eip7702Types {
  final List<Eip7702TypeField> delegation;
  final List<Eip7702TypeField> caveat;

  const Eip7702Types({
    required this.delegation,
    required this.caveat,
  });

  factory Eip7702Types.fromJson(Map<String, dynamic> json) {
    return Eip7702Types(
      delegation: (json['Delegation'] as List<dynamic>)
          .map((e) => Eip7702TypeField.fromJson(e as Map<String, dynamic>))
          .toList(),
      caveat: (json['Caveat'] as List<dynamic>)
          .map((e) => Eip7702TypeField.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Eip7702Message {
  final String delegate;
  final String delegator;
  final String authority;
  final List<dynamic> caveats;
  final int salt;

  const Eip7702Message({
    required this.delegate,
    required this.delegator,
    required this.authority,
    required this.caveats,
    required this.salt,
  });

  factory Eip7702Message.fromJson(Map<String, dynamic> json) {
    return Eip7702Message(
      delegate: json['delegate'] as String,
      delegator: json['delegator'] as String,
      authority: json['authority'] as String,
      caveats: json['caveats'] as List<dynamic>,
      salt: json['salt'] as int,
    );
  }
}

class RealUnitEip7702DataDto {
  final String relayerAddress;
  final String delegationManagerAddress;
  final String delegatorAddress;
  final int userNonce;
  final Eip7702Domain domain;
  final Eip7702Types types;
  final Eip7702Message message;
  final String tokenAddress;
  final String amountWei;
  final String depositAddress;

  const RealUnitEip7702DataDto({
    required this.relayerAddress,
    required this.delegationManagerAddress,
    required this.delegatorAddress,
    required this.userNonce,
    required this.domain,
    required this.types,
    required this.message,
    required this.tokenAddress,
    required this.amountWei,
    required this.depositAddress,
  });

  factory RealUnitEip7702DataDto.fromJson(Map<String, dynamic> json) {
    return RealUnitEip7702DataDto(
      relayerAddress: json['relayerAddress'] as String,
      delegationManagerAddress: json['delegationManagerAddress'] as String,
      delegatorAddress: json['delegatorAddress'] as String,
      userNonce: json['userNonce'] as int,
      domain: Eip7702Domain.fromJson(json['domain'] as Map<String, dynamic>),
      types: Eip7702Types.fromJson(json['types'] as Map<String, dynamic>),
      message: Eip7702Message.fromJson(json['message'] as Map<String, dynamic>),
      tokenAddress: json['tokenAddress'] as String,
      amountWei: json['amountWei'] as String,
      depositAddress: json['depositAddress'] as String,
    );
  }
}
