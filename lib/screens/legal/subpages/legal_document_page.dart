import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_legal_document_service.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

// Prefers API-sourced URLs when present; falls back to the bundled map
// otherwise. Within either map, prefers an exact language-code match
// and degrades to the first available URL. Exposed at top-level so it
// can be unit-tested without spinning up the full page widget.
@visibleForTesting
String? resolveLegalDocumentPdfUrl({
  required Map<String, String>? apiUrls,
  required Map<String, String>? fallbackUrls,
  required String languageCode,
}) {
  if (apiUrls != null && apiUrls.isNotEmpty) {
    return apiUrls[languageCode] ?? apiUrls.values.first;
  }
  if (fallbackUrls == null || fallbackUrls.isEmpty) return null;
  return fallbackUrls[languageCode] ?? fallbackUrls.values.first;
}

class LegalDocumentParams {
  final String title;
  final String assetBaseName;
  // Fallback PDF URLs (language → url). Used only if the API does not
  // return any URLs for [legalDocumentType] — the API is the source of
  // truth (closes audit V17), the local map is a last-resort fallback.
  final Map<String, String>? pdfUrls;
  // Maps to `LegalDocumentType` on the API. When set, the page fetches
  // current URLs from `/v1/legal-document?type=<this>` and prefers them
  // over the bundled [pdfUrls] map.
  final String? legalDocumentType;

  const LegalDocumentParams({
    required this.title,
    required this.assetBaseName,
    this.pdfUrls,
    this.legalDocumentType,
  });
}

class LegalDocumentPage extends StatefulWidget {
  final LegalDocumentParams params;

  const LegalDocumentPage({super.key, required this.params});

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  String? _markdownContent;
  // Resolved API URLs keyed by lowercase ISO 639-1 language code.
  // `null` ⇒ load not finished or no [legalDocumentType] configured.
  // Empty map ⇒ API responded but had no entry for the configured type.
  Map<String, String>? _apiPdfUrls;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
    _loadApiPdfUrls();
  }

  Future<void> _loadMarkdown() async {
    final code = context.read<SettingsBloc>().state.language.code;
    try {
      final content = await rootBundle.loadString(
        'assets/legal/${widget.params.assetBaseName}_$code.md',
      );
      if (mounted) setState(() => _markdownContent = content);
    } catch (_) {
      if (mounted) setState(() => _markdownContent = '');
    }
  }

  Future<void> _loadApiPdfUrls() async {
    final type = widget.params.legalDocumentType;
    if (type == null) return;
    try {
      final docs = await getIt<DfxLegalDocumentService>().getDocuments(type: type);
      final urls = <String, String>{
        for (final d in docs)
          if (d.language != null) d.language!.toLowerCase(): d.url,
      };
      if (mounted) setState(() => _apiPdfUrls = urls);
    } catch (e) {
      developer.log('Legal document fetch failed: $e', name: '$LegalDocumentPage');
      if (mounted) setState(() => _apiPdfUrls = const {});
    }
  }

  String? get _pdfUrl => resolveLegalDocumentPdfUrl(
    apiUrls: _apiPdfUrls,
    fallbackUrls: widget.params.pdfUrls,
    languageCode: context.read<SettingsBloc>().state.language.code,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.params.title),
    ),
    body: _markdownContent != null
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
        : const SizedBox.shrink(),
  );
}
