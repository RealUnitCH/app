import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
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
    try {
      final content = await rootBundle.loadString(
        'assets/legal/${widget.params.assetBaseName}_$code.md',
      );
      if (mounted) setState(() => _markdownContent = content);
    } catch (_) {
      if (mounted) setState(() => _markdownContent = '');
    }
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
