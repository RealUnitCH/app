import 'dart:async';
import 'dart:convert';

import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_config.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_engine.dart';

// @no-integration-test: Reown WalletKit plugin/relay boundary; covered by
//   FakeEngine unit tests — no device harness for live relay sessions.
// coverage:ignore-file — Reown WalletKit plugin/relay boundary; FakeEngine unit tests cover the port
class ReownWalletConnectEngine implements WalletConnectEngine {
  final _events = StreamController<WalletConnectIncoming>.broadcast();
  final _requestTopics = <int, String>{};
  final _proposalPairings = <String, String>{};

  ReownWalletKit? _walletKit;

  @override
  Stream<WalletConnectIncoming> get events => _events.stream;

  @override
  Future<void> init({
    required String address,
    required List<int> chainIds,
  }) async {
    if (_walletKit != null) return;

    // createInstance already calls init() (relay + verify). Do not init twice.
    // logLevel.nothing: no SDK chatter. Init happens only on first pair().
    final walletKit = await ReownWalletKit.createInstance(
      projectId: WalletConnectConfig.projectId,
      metadata: const PairingMetadata(
        name: WalletConnectConfig.metadataName,
        description: WalletConnectConfig.metadataName,
        url: WalletConnectConfig.metadataUrl,
        icons: ['https://realunit.app/favicon.ico'],
        redirect: Redirect(native: WalletConnectConfig.redirectNative),
      ),
      logLevel: LogLevel.nothing,
    );
    _subscribe(walletKit);
    for (final chainId in chainIds) {
      walletKit.registerAccount(
        chainId: 'eip155:$chainId',
        accountAddress: address,
      );
    }
    _walletKit = walletKit;
  }

  void _subscribe(ReownWalletKit walletKit) {
    walletKit.onSessionProposal.subscribe((event) {
      final metadata = event.params.proposer.metadata;
      final verifyContext = event.verifyContext;
      _proposalPairings[event.id.toString()] = event.params.pairingTopic;
      _events.add(
        WalletConnectSessionProposal(
          proposalId: event.id.toString(),
          originUrl: attestedOriginUrl(verifyContext?.origin),
          verifyStatus: _mapVerify(verifyContext),
          proposerName: metadata.name,
          proposerUrl: metadata.url,
        ),
      );
    });

    walletKit.onSessionRequest.subscribe((event) {
      _requestTopics[event.id] = event.topic;

      SessionRequest? pending;
      for (final request in walletKit.getPendingSessionRequests().values) {
        if (request.id == event.id && request.topic == event.topic) {
          pending = request;
          break;
        }
      }

      final verifyContext = pending?.verifyContext;
      _events.add(
        WalletConnectSessionRequest(
          requestId: event.id,
          topic: event.topic,
          method: event.method,
          params: event.params,
          originUrl: attestedOriginUrl(verifyContext?.origin),
          verifyStatus: _mapVerify(verifyContext),
          chainId: _parseChainId(event.chainId),
        ),
      );
    });

    walletKit.onSessionDelete.subscribe((event) {
      _events.add(WalletConnectSessionDeleted(topic: event.topic));
    });
  }

  WalletConnectVerifyStatus _mapVerify(VerifyContext? context) {
    return mapWalletConnectVerify(
      isScam: context?.isScam == true,
      validationName: context?.validation.name,
    );
  }

  int? _parseChainId(String chainId) {
    final value = chainId.split(':').lastOrNull;
    return value == null ? null : int.tryParse(value);
  }

  ReownWalletKit get _kit {
    final walletKit = _walletKit;
    if (walletKit == null) throw StateError('WalletConnect is not initialized.');
    return walletKit;
  }

  @override
  Future<void> pair(String uri) => _kit.pair(uri: Uri.parse(uri));

  @override
  Future<void> approveSession(
    String proposalId, {
    required String address,
  }) async {
    await _kit.approveSession(
      id: int.parse(proposalId),
      namespaces: {
        'eip155': Namespace(
          accounts: [
            for (final chainId in WalletConnectConfig.chainIds)
              'eip155:$chainId:$address',
          ],
          methods: WalletConnectConfig.methods,
          events: WalletConnectConfig.events,
        ),
      },
    );
  }

  @override
  Future<void> rejectSession(String proposalId) async {
    try {
      await _kit.rejectSession(
        id: int.parse(proposalId),
        reason: const ReownSignError(code: 5000, message: 'User rejected.'),
      );
    } finally {
      final pairingTopic = _proposalPairings.remove(proposalId);
      if (pairingTopic != null && pairingTopic.isNotEmpty) {
        try {
          await _kit.core.pairing.disconnect(topic: pairingTopic);
        } catch (_) {
          // Pairing may already be gone after rejectSession.
        }
      }
    }
  }

  @override
  Future<void> approveRequest(int requestId, String result) async {
    final topic = _requestTopics.remove(requestId);
    if (topic == null) throw StateError('Unknown WalletConnect request.');
    await _kit.respondSessionRequest(
      topic: topic,
      response: JsonRpcResponse(id: requestId, result: _decodeResult(result)),
    );
  }

  dynamic _decodeResult(String result) {
    if (result == 'null' || result.startsWith('[') || result.startsWith('{')) {
      return jsonDecode(result);
    }
    return result;
  }

  @override
  Future<void> rejectRequest(int requestId) async {
    final topic = _requestTopics.remove(requestId);
    if (topic == null) return;
    await _kit.respondSessionRequest(
      topic: topic,
      response: JsonRpcResponse(
        id: requestId,
        error: const JsonRpcError(code: 5000, message: 'User rejected.'),
      ),
    );
  }

  @override
  Future<void> disconnect(String topic) => _kit.disconnectSession(
        topic: topic,
        reason: const ReownSignError(code: 6000, message: 'User disconnected.'),
      );

  @override
  Future<void> reset() async {
    // Cold start after Delete Wallet / Forgot PIN: `_walletKit` is null but
    // WalletKit may still have persisted sessions in its default store.
    // Opening the kit without registerAccount loads that state so we can
    // disconnect it. Not boot init — only runs on wipe.
    var walletKit = _walletKit;
    if (walletKit == null) {
      try {
        walletKit = await ReownWalletKit.createInstance(
          projectId: WalletConnectConfig.projectId,
          metadata: const PairingMetadata(
            name: WalletConnectConfig.metadataName,
            description: WalletConnectConfig.metadataName,
            url: WalletConnectConfig.metadataUrl,
            icons: ['https://realunit.app/favicon.ico'],
            redirect: Redirect(native: WalletConnectConfig.redirectNative),
          ),
          logLevel: LogLevel.nothing,
        );
        _walletKit = walletKit;
      } catch (_) {
        _walletKit = null;
        _requestTopics.clear();
        _proposalPairings.clear();
        return;
      }
    }

    try {
      final sessions = walletKit.getActiveSessions();
      for (final session in sessions.values) {
        try {
          await walletKit.disconnectSession(
            topic: session.topic,
            reason: const ReownSignError(
              code: 6000,
              message: 'User disconnected.',
            ),
          );
        } catch (_) {
          // Session may already be gone.
        }
      }
    } catch (_) {
      // Listing active sessions must not block clearing the kit.
    }

    try {
      final pairings = walletKit.core.pairing.getPairings();
      for (final pairing in pairings) {
        try {
          await walletKit.core.pairing.disconnect(topic: pairing.topic);
        } catch (_) {
          // Pairing may already be gone.
        }
      }
    } catch (_) {
      // Listing pairings must not block clearing the kit.
    }

    _walletKit = null;
    _requestTopics.clear();
    _proposalPairings.clear();
  }
}
