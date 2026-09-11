enum WalletConnectVerifyStatus { valid, invalid, unknown, scam }

/// Maps Reown Verify fields without importing reown.
///
/// [validationName] must be the Dart enum `.name` (`VALID` / `INVALID` /
/// `SCAM` / `UNKNOWN`), not `toString()` (`Validation.VALID`), so a substring
/// match on `valid` cannot promote `SCAM` to [WalletConnectVerifyStatus.valid].
WalletConnectVerifyStatus mapWalletConnectVerify({
  required bool isScam,
  required String? validationName,
}) {
  if (isScam) return WalletConnectVerifyStatus.scam;
  switch (validationName?.toUpperCase()) {
    case 'VALID':
      return WalletConnectVerifyStatus.valid;
    case 'INVALID':
      return WalletConnectVerifyStatus.invalid;
    case 'SCAM':
      return WalletConnectVerifyStatus.scam;
    default:
      return WalletConnectVerifyStatus.unknown;
  }
}

/// Allowlist input is the Verify-attested origin only.
///
/// [verifyOrigin] is `verifyContext.origin`. Do not pass `metadata.url`
/// (attacker-controlled proposer URL).
String? attestedOriginUrl(String? verifyOrigin) {
  final attested = verifyOrigin?.trim();
  if (attested == null || attested.isEmpty) return null;
  return attested;
}

abstract class WalletConnectEngine {
  Future<void> init({required String address, required List<int> chainIds});
  Future<void> pair(String uri);
  Future<void> approveSession(String proposalId, {required String address});
  Future<void> rejectSession(String proposalId);
  Future<void> approveRequest(int requestId, String result);
  Future<void> rejectRequest(int requestId);
  Future<void> disconnect(String topic);
  Future<void> reset();
  Stream<WalletConnectIncoming> get events;
}

sealed class WalletConnectIncoming {
  const WalletConnectIncoming();
}

final class WalletConnectSessionProposal extends WalletConnectIncoming {
  final String proposalId;
  final String? originUrl;
  final WalletConnectVerifyStatus verifyStatus;
  final String proposerName;
  final String? proposerUrl;

  const WalletConnectSessionProposal({
    required this.proposalId,
    required this.originUrl,
    required this.verifyStatus,
    required this.proposerName,
    this.proposerUrl,
  });
}

final class WalletConnectSessionRequest extends WalletConnectIncoming {
  final int requestId;
  final String topic;
  final String method;
  final dynamic params;
  final String? originUrl;
  final WalletConnectVerifyStatus verifyStatus;
  final int? chainId;

  const WalletConnectSessionRequest({
    required this.requestId,
    required this.topic,
    required this.method,
    required this.params,
    required this.originUrl,
    required this.verifyStatus,
    this.chainId,
  });
}

final class WalletConnectSessionDeleted extends WalletConnectIncoming {
  final String topic;

  const WalletConnectSessionDeleted({required this.topic});
}
