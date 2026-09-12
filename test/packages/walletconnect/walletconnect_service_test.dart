import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_allowlist.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_engine.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_service.dart';

class _FakeEngine implements WalletConnectEngine {
  final _events = StreamController<WalletConnectIncoming>.broadcast();
  final rejectedSessions = <String>[];
  final rejectedRequests = <int>[];
  final disconnectedTopics = <String>[];
  final approvedSessions = <String>[];
  final approvedRequests = <int, String>{};
  var pairCalls = 0;
  var resetCalls = 0;
  Object? rejectRequestError;

  @override
  Stream<WalletConnectIncoming> get events => _events.stream;

  Object? initError;

  @override
  Future<void> init({required String address, required List<int> chainIds}) async {
    final error = initError;
    if (error != null) throw error;
  }

  @override
  Future<void> pair(String uri) async {
    pairCalls += 1;
  }

  @override
  Future<void> approveSession(String proposalId, {required String address}) async {
    approvedSessions.add(proposalId);
  }

  @override
  Future<void> rejectSession(String proposalId) async {
    rejectedSessions.add(proposalId);
  }

  @override
  Future<void> approveRequest(int requestId, String result) async {
    approvedRequests[requestId] = result;
  }

  @override
  Future<void> rejectRequest(int requestId) async {
    rejectedRequests.add(requestId);
    final error = rejectRequestError;
    if (error != null) throw error;
  }

  @override
  Future<void> disconnect(String topic) async {
    disconnectedTopics.add(topic);
  }

  @override
  Future<void> reset() async {
    resetCalls += 1;
  }

  void emit(WalletConnectIncoming incoming) => _events.add(incoming);
}

void main() {
  const address = '0x1111111111111111111111111111111111111111';
  const pairing =
      'wc:00e46b69-d0cc-4b3e-b6a2-cee442f97188@2?relay-protocol=irn&symKey=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  late _FakeEngine engine;
  late WalletConnectService service;
  late List<WalletConnectServiceError> errors;
  late List<WalletConnectUserPrompt> prompts;

  setUp(() {
    engine = _FakeEngine();
    service = WalletConnectService.forTesting(
      engine: engine,
      address: address,
      signMessage: (message) async => 'sig:$message',
    );
    errors = [];
    prompts = [];
    service.errors.listen(errors.add);
    service.prompts.listen(prompts.add);
  });

  test('rejects etherscan proposals', () async {
    engine.emit(
      const WalletConnectSessionProposal(
        proposalId: '9',
        originUrl: 'https://etherscan.io',
        verifyStatus: WalletConnectVerifyStatus.unknown,
        proposerName: 'Etherscan',
        proposerUrl: 'https://etherscan.io',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.rejectedSessions, ['9']);
    expect(errors, isNotEmpty);
    expect(errors.first.type, WalletConnectServiceErrorType.unsupportedProvider);
    expect(errors.first.message, WalletConnectAllowlist.unsupportedProviderMessage);
    expect(prompts, isEmpty);
  });

  test('rejects spoofed allowlisted URL with invalid verification', () async {
    engine.emit(
      const WalletConnectSessionProposal(
        proposalId: '8',
        originUrl: 'https://tokeninfo.aktionariat.com',
        verifyStatus: WalletConnectVerifyStatus.invalid,
        proposerName: 'Fake',
        proposerUrl: 'https://tokeninfo.aktionariat.com',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.rejectedSessions, ['8']);
    expect(errors.first.type, WalletConnectServiceErrorType.invalidVerification);
    expect(prompts, isEmpty);
  });

  test('rejects allowlisted URL when Verify is unknown', () async {
    engine.emit(
      const WalletConnectSessionProposal(
        proposalId: '7',
        originUrl: 'https://tokeninfo.aktionariat.com',
        verifyStatus: WalletConnectVerifyStatus.unknown,
        proposerName: 'Aktionariat',
        proposerUrl: 'https://tokeninfo.aktionariat.com',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.rejectedSessions, ['7']);
    expect(errors.first.type, WalletConnectServiceErrorType.invalidVerification);
    expect(prompts, isEmpty);
  });

  test('disconnects a policy-fail request even if reject throws', () async {
    engine.rejectRequestError = StateError('relay down');
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 22,
        topic: 'topic-etherscan',
        method: 'personal_sign',
        params: ['hello', address],
        originUrl: 'https://etherscan.io',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.rejectedRequests, [22]);
    expect(engine.disconnectedTopics, ['topic-etherscan']);
    expect(prompts, isEmpty);
  });

  test('rejects policy-fail session requests and disconnects the topic', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 21,
        topic: 'topic-etherscan',
        method: 'personal_sign',
        params: ['hello', address],
        originUrl: 'https://etherscan.io',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.rejectedRequests, [21]);
    expect(engine.disconnectedTopics, ['topic-etherscan']);
    expect(errors.first.type, WalletConnectServiceErrorType.unsupportedProvider);
    expect(prompts, isEmpty);
  });

  test('prompts for Verify-valid Aktionariat proposals', () async {
    engine.emit(
      const WalletConnectSessionProposal(
        proposalId: '1',
        originUrl: 'https://tokeninfo.aktionariat.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
        proposerName: 'Aktionariat',
        proposerUrl: 'https://tokeninfo.aktionariat.com',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.rejectedSessions, isEmpty);
    expect(prompts, hasLength(1));
  });

  test('personal_sign happy path', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 3,
        topic: 'topic',
        method: 'personal_sign',
        params: ['hello', address],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(prompts, hasLength(1));
    await service.approvePrompt(prompts.first);
    expect(engine.approvedRequests[3], 'sig:hello');
  });

  test('session delete blocks a later approve from signing', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 11,
        topic: 'topic',
        method: 'personal_sign',
        params: ['hello', address],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(prompts, hasLength(1));
    engine.emit(const WalletConnectSessionDeleted(topic: 'topic'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(errors.last.type, WalletConnectServiceErrorType.sessionEnded);
    expect(
      () => service.approvePrompt(prompts.first),
      throwsA(isA<StateError>()),
    );
    expect(engine.approvedRequests.containsKey(11), isFalse);
  });

  test('session delete during signing rejects instead of approving', () async {
    final started = Completer<void>();
    final delayed = Completer<String>();
    final signingService = WalletConnectService.forTesting(
      engine: engine,
      address: address,
      signMessage: (message) async {
        started.complete();
        return delayed.future;
      },
    );
    final signingErrors = <WalletConnectServiceError>[];
    final signingPrompts = <WalletConnectUserPrompt>[];
    signingService.errors.listen(signingErrors.add);
    signingService.prompts.listen(signingPrompts.add);

    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 12,
        topic: 'topic',
        method: 'personal_sign',
        params: ['hello', address],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final pending = signingService.approvePrompt(signingPrompts.first);
    await started.future;
    engine.emit(const WalletConnectSessionDeleted(topic: 'topic'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    delayed.complete('sig:hello');
    await expectLater(pending, throwsA(isA<StateError>()));
    expect(engine.approvedRequests.containsKey(12), isFalse);
    expect(engine.rejectedRequests, contains(12));
  });

  test('eth_sendTransaction is rejected without prompting', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 4,
        topic: 'topic',
        method: 'eth_sendTransaction',
        params: [
          {'to': '0x2222222222222222222222222222222222222222'},
        ],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(prompts, isEmpty);
    expect(engine.rejectedRequests, [4]);
    expect(errors.first.type, WalletConnectServiceErrorType.sendTransactionUnsupported);
  });

  test('rejects scam verification even for an allowlisted origin', () async {
    engine.emit(
      const WalletConnectSessionProposal(
        proposalId: '6',
        originUrl: 'https://tokeninfo.aktionariat.com',
        verifyStatus: WalletConnectVerifyStatus.scam,
        proposerName: 'Aktionariat',
        proposerUrl: 'https://tokeninfo.aktionariat.com',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.rejectedSessions, ['6']);
    expect(errors.first.type, WalletConnectServiceErrorType.invalidVerification);
    expect(prompts, isEmpty);
  });

  test('eth_signTransaction is rejected without prompting', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 5,
        topic: 'topic',
        method: 'eth_signTransaction',
        params: [
          {'to': '0x2222222222222222222222222222222222222222'},
        ],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(prompts, isEmpty);
    expect(engine.rejectedRequests, [5]);
    expect(errors.first.type, WalletConnectServiceErrorType.sendTransactionUnsupported);
  });

  test('rejects a Verify-valid proposal whose attested origin is null', () async {
    engine.emit(
      const WalletConnectSessionProposal(
        proposalId: '10',
        originUrl: null,
        verifyStatus: WalletConnectVerifyStatus.valid,
        proposerName: 'Aktionariat',
        proposerUrl: 'https://tokeninfo.aktionariat.com',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.rejectedSessions, ['10']);
    expect(errors.first.type, WalletConnectServiceErrorType.unsupportedProvider);
    expect(prompts, isEmpty);
  });

  test('pair requires a v2 WalletConnect URI', () async {
    await service.ensureInitialized();
    await service.pair(pairing);
    expect(engine.pairCalls, 1);
    expect(
      () => service.pair('https://etherscan.io'),
      throwsA(isA<FormatException>()),
    );
  });

  test('reset calls engine.reset and allows pair again', () async {
    await service.ensureInitialized();
    await service.pair(pairing);
    expect(engine.pairCalls, 1);

    await service.reset();
    expect(engine.resetCalls, 1);

    await service.pair(pairing);
    expect(engine.pairCalls, 2);
  });

  test('debug wallet rejects personal_sign without prompting', () async {
    final debugEngine = _FakeEngine();
    final debugService = WalletConnectService.forTesting(
      engine: debugEngine,
      address: address,
      signMessage: (message) async => 'sig:$message',
      walletType: WalletType.debug,
    );
    final debugErrors = <WalletConnectServiceError>[];
    final debugPrompts = <WalletConnectUserPrompt>[];
    debugService.errors.listen(debugErrors.add);
    debugService.prompts.listen(debugPrompts.add);

    debugEngine.emit(
      const WalletConnectSessionRequest(
        requestId: 11,
        topic: 'topic',
        method: 'personal_sign',
        params: ['hello', address],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(debugPrompts, isEmpty);
    expect(debugEngine.rejectedRequests, [11]);
    expect(debugErrors, isNotEmpty);
    expect(debugErrors.first.type, WalletConnectServiceErrorType.signingFailed);
  });

  test('eth_accounts is approved without a prompt', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 30,
        topic: 'topic',
        method: 'eth_accounts',
        params: [],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(prompts, isEmpty);
    expect(engine.approvedRequests[30], jsonEncode([address]));
  });

  test('eth_chainId is approved without a prompt', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 31,
        topic: 'topic',
        method: 'eth_chainId',
        params: [],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
        chainId: 1,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.approvedRequests[31], '0x1');
  });

  test('wallet_switchEthereumChain accepts a configured chain', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 32,
        topic: 'topic',
        method: 'wallet_switchEthereumChain',
        params: [
          {'chainId': '0x1'},
        ],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.approvedRequests[32], 'null');
  });

  test('wallet_switchEthereumChain rejects an unknown chain', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 33,
        topic: 'topic',
        method: 'wallet_switchEthereumChain',
        params: [
          {'chainId': '0x38'},
        ],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.rejectedRequests, contains(33));
  });

  test('unknown methods are rejected with unsupportedMethod', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 34,
        topic: 'topic',
        method: 'wallet_watchAsset',
        params: [],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.rejectedRequests, contains(34));
    expect(errors.first.type, WalletConnectServiceErrorType.unsupportedMethod);
  });

  test('eth_signTypedData_v4 prompts and signs', () async {
    final typedEngine = _FakeEngine();
    final typedService = WalletConnectService.forTesting(
      engine: typedEngine,
      address: address,
      signMessage: (message) async => 'sig:$message',
      signTypedData: (chainId, json) async => 'typed:$chainId:$json',
    );
    final typedPrompts = <WalletConnectUserPrompt>[];
    typedService.prompts.listen(typedPrompts.add);

    typedEngine.emit(
      const WalletConnectSessionRequest(
        requestId: 35,
        topic: 'topic',
        method: 'eth_signTypedData_v4',
        params: [
          address,
          '{"domain":{}}',
        ],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
        chainId: 1,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(typedPrompts, hasLength(1));
    await typedService.approvePrompt(typedPrompts.first);
    expect(typedEngine.approvedRequests[35], startsWith('typed:1:'));
  });

  test('eth_signTypedData_v4 without a configured chain is rejected', () async {
    final typedEngine = _FakeEngine();
    final typedService = WalletConnectService.forTesting(
      engine: typedEngine,
      address: address,
      signMessage: (message) async => 'sig:$message',
      signTypedData: (chainId, json) async => 'typed:$chainId:$json',
    );
    final typedPrompts = <WalletConnectUserPrompt>[];
    typedService.prompts.listen(typedPrompts.add);

    typedEngine.emit(
      const WalletConnectSessionRequest(
        requestId: 37,
        topic: 'topic',
        method: 'eth_signTypedData_v4',
        params: [
          address,
          '{"domain":{}}',
        ],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(typedPrompts, hasLength(1));
    await expectLater(
      typedService.approvePrompt(typedPrompts.first),
      throwsA(isA<FormatException>()),
    );
    expect(typedEngine.rejectedRequests, contains(37));
    expect(typedEngine.approvedRequests.containsKey(37), isFalse);
  });

  test('approvePrompt then rejectPrompt on a proposal', () async {
    engine.emit(
      const WalletConnectSessionProposal(
        proposalId: '40',
        originUrl: 'https://tokeninfo.aktionariat.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
        proposerName: 'Aktionariat',
        proposerUrl: 'https://tokeninfo.aktionariat.com',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await service.approvePrompt(prompts.first);
    expect(engine.approvedSessions, ['40']);

    engine.emit(
      const WalletConnectSessionProposal(
        proposalId: '41',
        originUrl: 'https://tokeninfo.aktionariat.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
        proposerName: 'Aktionariat',
        proposerUrl: 'https://tokeninfo.aktionariat.com',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await service.rejectPrompt(prompts.last);
    expect(engine.rejectedSessions, contains('41'));
  });

  test('personal_sign hex payload is decoded for the preview', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 36,
        topic: 'topic',
        method: 'personal_sign',
        params: ['0x68656c6c6f', address],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(prompts, hasLength(1));
    expect(
      (prompts.first as WalletConnectRequestPrompt).messagePreview,
      'hello',
    );
  });

  test('proposal prompt exposes the attested origin', () async {
    engine.emit(
      const WalletConnectSessionProposal(
        proposalId: '50',
        originUrl: 'https://tokeninfo.aktionariat.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
        proposerName: 'Aktionariat',
        proposerUrl: 'https://evil.example',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(prompts.first.originUrl, 'https://tokeninfo.aktionariat.com');
  });

  test('init failure is swallowed so a later pair can retry', () async {
    engine.initError = StateError('kit down');
    await service.ensureInitialized();
    engine.initError = null;
    await service.pair(pairing);
    expect(engine.pairCalls, 1);
  });

  test('debug wallet rejects typed data without prompting', () async {
    final debugEngine = _FakeEngine();
    final debugService = WalletConnectService.forTesting(
      engine: debugEngine,
      address: address,
      signMessage: (message) async => 'sig:$message',
      signTypedData: (chainId, json) async => 'typed',
      walletType: WalletType.debug,
    );
    final debugPrompts = <WalletConnectUserPrompt>[];
    debugService.prompts.listen(debugPrompts.add);
    debugEngine.emit(
      const WalletConnectSessionRequest(
        requestId: 51,
        topic: 'topic',
        method: 'eth_signTypedData_v4',
        params: [
          address,
          '{"domain":{}}',
        ],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
        chainId: 1,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(debugPrompts, isEmpty);
    expect(debugEngine.rejectedRequests, [51]);
  });

  test('approving typed data without a JSON payload is rejected', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 52,
        topic: 'topic',
        method: 'eth_signTypedData_v4',
        params: [address],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
        chainId: 1,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(prompts, hasLength(1));
    await expectLater(
      service.approvePrompt(prompts.first),
      throwsA(isA<FormatException>()),
    );
    expect(engine.rejectedRequests, contains(52));
  });

  test('rejectPrompt rejects a sign request', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 53,
        topic: 'topic',
        method: 'personal_sign',
        params: ['hello', address],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await service.rejectPrompt(prompts.first);
    expect(engine.rejectedRequests, contains(53));
  });

  test('wallet_switchEthereumChain accepts a decimal chain id', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 54,
        topic: 'topic',
        method: 'wallet_switchEthereumChain',
        params: [
          {'chainId': '1'},
        ],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(engine.approvedRequests[54], 'null');
  });

  test('personal_sign preview falls back when params are only the address', () async {
    engine.emit(
      const WalletConnectSessionRequest(
        requestId: 55,
        topic: 'topic',
        method: 'personal_sign',
        params: [address],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(prompts, hasLength(1));
    expect((prompts.first as WalletConnectRequestPrompt).messagePreview, isNotEmpty);
  });

  test('approvePrompt rejects an unknown request method', () async {
    const prompt = WalletConnectRequestPrompt(
      request: WalletConnectSessionRequest(
        requestId: 56,
        topic: 'topic',
        method: 'wallet_watchAsset',
        params: [],
        originUrl: 'https://app.frankencoin.com',
        verifyStatus: WalletConnectVerifyStatus.valid,
      ),
      messagePreview: '',
    );
    await service.pair(pairing);
    await service.approvePrompt(prompt);
    expect(engine.rejectedRequests, contains(56));
  });
}
