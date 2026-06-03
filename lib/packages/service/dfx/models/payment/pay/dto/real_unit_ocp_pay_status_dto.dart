/// Mirrors the backend `PaymentLinkPaymentStatus` enum 1:1 (type-safe DTO
/// mirroring, not local business logic). The backend remains the authority on
/// the payment status; the app renders it and uses [isTerminal] / [isCompleted]
/// only to decide when to stop polling and which UI state to show.
enum OcpPaymentStatus {
  pending('Pending'),
  completed('Completed'),
  cancelled('Cancelled'),
  expired('Expired'),
  unknown('')
  ;

  final String value;

  const OcpPaymentStatus(this.value);

  static OcpPaymentStatus fromValue(String value) {
    return OcpPaymentStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => OcpPaymentStatus.unknown,
    );
  }

  /// Polling stops once the payment reaches a final state.
  bool get isTerminal => this == completed || this == cancelled || this == expired;

  bool get isCompleted => this == completed;
}

/// Response of `GET /v1/realunit/pay/:id/status`.
class RealUnitOcpPayStatusDto {
  final OcpPaymentStatus status;

  const RealUnitOcpPayStatusDto({required this.status});

  factory RealUnitOcpPayStatusDto.fromJson(Map<String, dynamic> json) {
    return RealUnitOcpPayStatusDto(
      status: OcpPaymentStatus.fromValue(json['status'] as String),
    );
  }
}
