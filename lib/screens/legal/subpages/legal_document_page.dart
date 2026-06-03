import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

class LegalDocumentParams {
  final String title;
  final String assetBaseName;
  final Map<String, String>? pdfUrls;

  const LegalDocumentParams({
    required this.title,
    required this.assetBaseName,
    this.pdfUrls,
  });
}

class LegalDocumentPage extends StatefulWidget {
  final LegalDocumentParams params;

  /// Pre-loaded markdown content for golden tests. When provided, skips the
  /// rootBundle asset load so the page renders the loaded state synchronously.
  @visibleForTesting
  final String? initialMarkdownContent;

  const LegalDocumentPage({
    super.key,
    required this.params,
    this.initialMarkdownContent,
  });

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  String? _markdownContent;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMarkdownContent != null) {
      _markdownContent = widget.initialMarkdownContent;
    } else {
      _loadMarkdown();
    }
  }

  Future<void> _loadMarkdown() async {
    final code = context.read<SettingsBloc>().state.language.code;
    final assetPath = 'assets/legal/${widget.params.assetBaseName}_$code.md';
    try {
      // cache: false so Retry after a transient failure actually re-reads the
      // asset instead of replaying rootBundle's cached error for this key.
      final content = await rootBundle.loadString(assetPath, cache: false);
      if (mounted) setState(() => _markdownContent = content);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load legal document "${widget.params.assetBaseName}"',
        name: 'realunit_wallet.legal',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // SEVERE
      );
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void _retryLoad() {
    setState(() {
      _loadFailed = false;
      _markdownContent = null;
    });
    _loadMarkdown();
  }

  String? get _pdfUrl {
    if (widget.params.pdfUrls == null) return null;
    final code = context.read<SettingsBloc>().state.language.code;
    return widget.params.pdfUrls![code] ?? widget.params.pdfUrls!.values.first;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.params.title),
    ),
    body: _loadFailed
        ? _buildError(context)
        : _markdownContent != null
        ? Column(
            children: [
              Expanded(
                child: Markdown(
                  data: _markdownContent!,
                  styleSheet: MarkdownStyleSheet(
                    h2Padding: const .only(top: 16),
                  ),
                  onTapLink: (text, href, title) {
                    if (href == null || href.startsWith('mailto:') || href.contains('@')) return;
                    context.pushNamed(
                      AppRoutes.webView,
                      extra: WebViewRouteParams(
                        title: text,
                        url: Uri.parse(href),
                      ),
                    );
                  },
                ),
              ),
              if (_pdfUrl != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const .all(20.0),
                    child: AppFilledButton(
                      variant: .secondary,
                      onPressed: () => context.pushNamed(
                        AppRoutes.webView,
                        extra: WebViewRouteParams(
                          title: S.of(context).originalPdf,
                          url: Uri.parse(_pdfUrl!),
                          showExternalBrowserButton: true,
                        ),
                      ),
                      icon: Icons.picture_as_pdf_outlined,
                      label: S.of(context).originalPdf,
                    ),
                  ),
                ),
            ],
          )
        // Documents load from a bundled asset (effectively synchronous), so the
        // brief null frame stays blank rather than flashing a spinner.
        : const SizedBox.shrink(),
  );

  // Mirrors the canonical full-page error view in
  // settings_currencies_page.dart (`_ErrorView`); keep the two in sync.
  Widget _buildError(BuildContext context) => Center(
    key: const ValueKey('legalDocumentLoadError'),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: RealUnitColors.neutral500,
          ),
          const SizedBox(height: 12),
          Text(
            S.of(context).legalDocumentLoadFailed,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).legalDocumentLoadFailedDescription,
            style: const TextStyle(color: RealUnitColors.neutral500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            key: const ValueKey('legalDocumentRetryButton'),
            onPressed: _retryLoad,
            child: Text(S.of(context).retry),
          ),
        ],
      ),
    ),
  );
}
