import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/walletconnect/walletconnect_service.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

/// Destination of a WalletConnect QR / deeplink pairing. Unique type so the
/// scanner-navigation catalog can `findsOne` it.
class WalletConnectSessionView extends StatelessWidget {
  final String? pairingUri;
  final WalletConnectUserPrompt? initialPrompt;

  const WalletConnectSessionView({
    super.key,
    this.pairingUri,
    this.initialPrompt,
  });

  @override
  Widget build(BuildContext context) => WalletConnectSessionPage(
        pairingUri: pairingUri,
        initialPrompt: initialPrompt,
      );
}

class WalletConnectSessionPage extends StatefulWidget {
  final String? pairingUri;
  final WalletConnectUserPrompt? initialPrompt;

  const WalletConnectSessionPage({
    super.key,
    this.pairingUri,
    this.initialPrompt,
  });

  @override
  State<WalletConnectSessionPage> createState() => _WalletConnectSessionPageState();
}

class _WalletConnectSessionPageState extends State<WalletConnectSessionPage> {
  StreamSubscription<WalletConnectUserPrompt>? _prompts;
  StreamSubscription<WalletConnectServiceError>? _errors;
  WalletConnectUserPrompt? _prompt;
  bool _busy = false;

  WalletConnectService get _service => getIt<WalletConnectService>();

  @override
  void initState() {
    super.initState();
    _prompt = widget.initialPrompt;
    _prompts = _service.prompts.listen((prompt) {
      if (!mounted) return;
      setState(() => _prompt = prompt);
    });
    _errors = _service.errors.listen((error) {
      if (!mounted) return;
      final message = switch (error.type) {
        WalletConnectServiceErrorType.unsupportedProvider =>
          S.of(context).walletConnectUnsupportedProvider,
        WalletConnectServiceErrorType.invalidVerification =>
          S.of(context).walletConnectInvalidVerification,
        WalletConnectServiceErrorType.invalidUri =>
          S.of(context).walletConnectInvalidUri,
        WalletConnectServiceErrorType.unsupportedMethod =>
          S.of(context).walletConnectUnsupportedMethod,
        WalletConnectServiceErrorType.sendTransactionUnsupported =>
          S.of(context).walletConnectSendTransactionUnsupported,
        WalletConnectServiceErrorType.signingFailed =>
          S.of(context).walletConnectSigningFailed,
        WalletConnectServiceErrorType.sessionEnded =>
          S.of(context).walletConnectSessionEnded,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: RealUnitColors.status.red600,
        ),
      );
      if (error.type == WalletConnectServiceErrorType.unsupportedProvider ||
          error.type == WalletConnectServiceErrorType.invalidVerification ||
          error.type == WalletConnectServiceErrorType.sessionEnded) {
        Navigator.of(context).maybePop();
      }
    });
    final uri = widget.pairingUri;
    if (uri != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_pair(uri));
      });
    }
  }

  Future<void> _pair(String uri) async {
    try {
      await _service.pair(uri);
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).walletConnectInvalidUri),
          backgroundColor: RealUnitColors.status.red600,
        ),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_prompts?.cancel());
    unawaited(_errors?.cancel());
    super.dispose();
  }

  Future<void> _approve() async {
    final prompt = _prompt;
    if (prompt == null) return;
    setState(() => _busy = true);
    try {
      await _service.approvePrompt(prompt);
      // A newer prompt may have arrived while approve awaited unlock/relay.
      if (mounted && identical(_prompt, prompt)) {
        setState(() => _prompt = null);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: RealUnitColors.status.red600,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final prompt = _prompt;
    if (prompt == null) {
      Navigator.of(context).maybePop();
      return;
    }
    await _service.rejectPrompt(prompt);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).walletConnectConnect)),
      body: SafeArea(
        child: _prompt == null
            ? const Center(child: CupertinoActivityIndicator())
            : ScrollableActionsLayout(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                body: _body(context, _prompt!),
                actions: [
                  FilledButton(
                    onPressed: _busy ? null : _approve,
                    child: Text(
                      _prompt is WalletConnectRequestPrompt
                          ? S.of(context).walletConnectSign
                          : S.of(context).walletConnectApprove,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : _reject,
                    child: Text(S.of(context).walletConnectReject),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _body(BuildContext context, WalletConnectUserPrompt prompt) {
    switch (prompt) {
      case WalletConnectProposalPrompt():
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.of(context).walletConnectProposalTitle(prompt.proposal.proposerName),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(prompt.proposal.originUrl ?? ''),
          ],
        );
      case WalletConnectRequestPrompt():
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.of(context).walletConnectSignTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(prompt.originUrl ?? ''),
            const SizedBox(height: 12),
            Text(prompt.messagePreview),
          ],
        );
    }
  }
}
