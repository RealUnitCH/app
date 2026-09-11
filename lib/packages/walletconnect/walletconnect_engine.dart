enum WalletConnectVerifyStatus { valid, invalid, unknown, scam }

abstract class WalletConnectEngine {
  Future<void> init({required String address, required List<int> chainIds});
  Future<void> pair(String uri);
  Future<void> approveSession(String proposalId, {required String address});
  Future<void> rejectSession(String proposalId);
  Future<void> approveRequest(int requestId, String result);
  Future<void> rejectRequest(int requestId);
  Future<void> disconnect(String topic);
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
