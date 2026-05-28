import 'package:realunit_wallet/packages/service/dfx/models/kyc/kyc_level.dart';

class UserDto {
  final String? mail;
  final UserKycDto kyc;
  final UserCapabilitiesDto capabilities;

  /// Lowercased blockchain addresses currently associated with this user
  /// account (the `addresses[].address` list from `/v2/user`). This is a
  /// best-effort hint: absent/empty data is treated as unknown by callers, not
  /// as proof that the locally-active wallet is unregistered.
  final List<String> addresses;

  const UserDto({
    this.mail,
    required this.kyc,
    this.capabilities = const UserCapabilitiesDto(),
    this.addresses = const [],
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      mail: json['mail'] as String?,
      kyc: UserKycDto.fromJson(json['kyc'] as Map<String, dynamic>),
      capabilities: json['capabilities'] != null
          ? UserCapabilitiesDto.fromJson(json['capabilities'] as Map<String, dynamic>)
          : const UserCapabilitiesDto(),
      addresses:
          (json['addresses'] as List<dynamic>?)
              ?.map((a) => a is Map<String, dynamic> ? a['address'] : null)
              .whereType<String>()
              .map((address) => address.toLowerCase())
              .toList() ??
          const [],
    );
  }
}

class UserKycDto {
  final String hash;
  final KycLevel level;
  final bool dataComplete;

  const UserKycDto({
    required this.hash,
    required this.level,
    required this.dataComplete,
  });

  factory UserKycDto.fromJson(Map<String, dynamic> json) {
    return UserKycDto(
      hash: json['hash'] as String,
      level: KycLevelExtension.fromValue(json['level'] as int),
      dataComplete: json['dataComplete'] as bool,
    );
  }
}

// Mirror of `UserCapabilitiesDto` on the API. Authoritative per-action
// edit gating — the app renders Edit affordances from these flags
// instead of inferring them from KYC step status. Defaults are
// conservative (everything `false`) so pre-PR backends do not silently
// expose actions the API isn't yet ready to handle.
class UserCapabilitiesDto {
  final bool canEditName;
  final bool canEditMail;
  final bool canEditPhone;
  final bool canEditAddress;

  const UserCapabilitiesDto({
    this.canEditName = false,
    this.canEditMail = false,
    this.canEditPhone = false,
    this.canEditAddress = false,
  });

  factory UserCapabilitiesDto.fromJson(Map<String, dynamic> json) {
    return UserCapabilitiesDto(
      canEditName: json['canEditName'] as bool? ?? false,
      canEditMail: json['canEditMail'] as bool? ?? false,
      canEditPhone: json['canEditPhone'] as bool? ?? false,
      canEditAddress: json['canEditAddress'] as bool? ?? false,
    );
  }
}
