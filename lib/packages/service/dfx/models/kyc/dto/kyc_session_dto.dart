import 'package:realunit_wallet/packages/service/dfx/models/kyc/dto/kyc_level_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

class KycSessionDto extends KycLevelDto {
  final KycStepSessionDto? currentStep;

  const KycSessionDto({required super.kycLevel, required super.kycSteps, this.currentStep});

  factory KycSessionDto.fromJson(Map<String, dynamic> json) {
    return KycSessionDto(
      kycLevel: KycLevelExtension.fromValue(json['kycLevel'] as int),
      kycSteps: (json['kycSteps'] as List<dynamic>)
          .map((e) => KycStepDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentStep: json['currentStep'] != null
          ? KycStepSessionDto.fromJson(json['currentStep'] as Map<String, dynamic>)
          : null,
    );
  }
}

class KycStepSessionDto extends KycStepDto {
  final KycSessionInfoDto session;

  const KycStepSessionDto({
    required this.session,
    required super.name,
    super.type,
    required super.status,
    super.reason,
    required super.sequenceNumber,
    required super.isCurrent,
  });

  factory KycStepSessionDto.fromJson(Map<String, dynamic> json) {
    return KycStepSessionDto(
      session: KycSessionInfoDto.fromJson(json['session'] as Map<String, dynamic>),
      name: KycStepNameExtension.fromValue(json['name'] as String),
      type: json['type'] != null ? KycStepTypeExtension.fromValue(json['type'] as String) : null,
      status: KycStepStatusExtension.fromValue(json['status'] as String),
      reason: json['reason'] != null
          ? KycStepReasonExtension.fromValue(json['reason'] as String)
          : null,
      sequenceNumber: json['sequenceNumber'] as int,
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }
}

class KycSessionInfoDto {
  final String url;
  final UrlType type;

  const KycSessionInfoDto({required this.url, required this.type});

  factory KycSessionInfoDto.fromJson(Map<String, dynamic> json) {
    return KycSessionInfoDto(
      url: json['url'] as String,
      type: UrlTypeExtension.fromJson(json['type'] as String),
    );
  }
}

enum UrlType { browser, api, token, none }

extension UrlTypeExtension on UrlType {
  static UrlType fromJson(String value) {
    switch (value) {
      case 'Browser':
        return UrlType.browser;
      case 'API':
        return UrlType.api;
      case 'Token':
        return UrlType.token;
      case 'None':
        return UrlType.none;
      default:
        throw ArgumentError('Unknown UrlType: $value');
    }
  }
}
