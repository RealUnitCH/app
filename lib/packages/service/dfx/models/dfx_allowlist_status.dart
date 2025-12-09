class DfxAllowlistStatus {
  final String address;

  /// Address needs to be registered as RealUnit customer to be able to receive.
  final bool canReceive;

  /// Address is suspended, buying is not possible.
  final bool isForbidden;

  /// Privileged address.
  final bool isPowerlisted;

  DfxAllowlistStatus({
    required this.address,
    required this.canReceive,
    required this.isForbidden,
    required this.isPowerlisted,
  });

  factory DfxAllowlistStatus.fromJson(Map<String, dynamic> json) {
    return DfxAllowlistStatus(
      address: json['address'] as String,
      canReceive: json['canReceive'] as bool,
      isForbidden: json['isForbidden'] as bool,
      isPowerlisted: json['isPowerlisted'] as bool,
    );
  }
}
