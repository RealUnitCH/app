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

// Wählt aus den API-Sprachvarianten deterministisch die passende PDF-URL:
// exakter Sprach-Match → 'en' → 'de' → erste verfügbare. Es gibt keinen
// hardcoded Fallback mehr — leerer Input ⇒ `null` (closes audit V17).
@visibleForTesting
String? resolveLegalDocumentPdfUrl({
  required Map<String, String> apiUrls,
  required String languageCode,
}) {
  if (apiUrls.isEmpty) return null;
  return apiUrls[languageCode] ?? apiUrls['en'] ?? apiUrls['de'] ?? apiUrls.values.first;
}

class LegalDocumentParams {
  final String title;
  final String assetBaseName;
  // Bildet auf `LegalDocumentType` der API ab. Wenn gesetzt, lädt die Seite
  // `/v1/legal-document?type=<this>` und rendert die zurückgegebene URL als
  // "Original PDF"-Button. Es gibt keinen hardcoded Fallback (audit V17).
  final String? legalDocumentType;

  const LegalDocumentParams({
    required this.title,
    required this.assetBaseName,
    this.legalDocumentType,
  });
}

class LegalDocumentPage extends StatefulWidget {
  final LegalDocumentParams params;

  const LegalDocumentPage({super.key, required this.params});

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

// PDF-Ladezustand für die "Original PDF"-Sektion.
// `loading` ⇒ API-Call läuft noch, Skeleton-Button.
// `available` ⇒ URL vorhanden, klickbarer Button.
// `unavailable` ⇒ API beantwortet/fehlgeschlagen ohne passende URL,
// Retry-Button.
enum _PdfStatus { loading, available, unavailable }

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
    // Beim Retry-Tap (Status "unavailable" → "loading") muss `_apiPdfUrls`
    // zurück auf `null` springen, damit der Button kurzzeitig den
    // Loading-Spinner zeigt. `_apiPdfUrls != null` impliziert, dass der
    // erste Build durchgelaufen ist, also ist setState hier sicher.
    if (mounted && _apiPdfUrls != null) {
      setState(() => _apiPdfUrls = null);
    }
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

  _PdfStatus get _pdfStatus {
    // Kein API-Typ konfiguriert ⇒ keine PDF-Sektion. Wird im build()
    // über `params.legalDocumentType == null` ausgeblendet.
    if (widget.params.legalDocumentType == null) return _PdfStatus.unavailable;
    final urls = _apiPdfUrls;
    if (urls == null) return _PdfStatus.loading;
    final resolved = resolveLegalDocumentPdfUrl(
      apiUrls: urls,
      languageCode: context.read<SettingsBloc>().state.language.code,
    );
    return resolved == null ? _PdfStatus.unavailable : _PdfStatus.available;
  }

  String? get _pdfUrl {
    final urls = _apiPdfUrls;
    if (urls == null) return null;
    return resolveLegalDocumentPdfUrl(
      apiUrls: urls,
      languageCode: context.read<SettingsBloc>().state.language.code,
    );
  }

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
              if (widget.params.legalDocumentType != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const .all(20.0),
                    child: _buildPdfButton(context),
                  ),
                ),
            ],
          )
        : const SizedBox.shrink(),
  );

  Widget _buildPdfButton(BuildContext context) {
    switch (_pdfStatus) {
      case _PdfStatus.loading:
        return AppFilledButton(
          variant: .secondary,
          state: .loading,
          label: S.of(context).pdfLoading,
        );
      case _PdfStatus.unavailable:
        return AppFilledButton(
          variant: .secondary,
          onPressed: _loadApiPdfUrls,
          icon: Icons.refresh,
          label: S.of(context).pdfNotAvailable,
        );
      case _PdfStatus.available:
        return AppFilledButton(
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
        );
    }
  }
}
