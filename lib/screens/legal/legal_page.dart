import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';

class LegalPage extends StatefulWidget {
  static const routeName = '/termsOfUse';

  const LegalPage({super.key});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  String? _markdownContent;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  Future<void> _loadMarkdown() async {
    final code = context.read<SettingsBloc>().state.language.code;
    try {
      final content = await rootBundle.loadString('assets/legal/terms_of_use_$code.md');
      if (mounted) setState(() => _markdownContent = content);
    } catch (_) {
      if (mounted) setState(() => _markdownContent = '');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(S.of(context).termsOfUse),
    ),
    body: _markdownContent == null
        ? const Center(child: CupertinoActivityIndicator())
        : Markdown(
            data: _markdownContent!,
            styleSheet: MarkdownStyleSheet(
              h2Padding: const EdgeInsets.only(top: 16),
            ),
            onTapLink: (text, href, title) {
              if (href == null) return;
              context.push(
                '/webView',
                extra: WebViewRouteParams(
                  title: text,
                  url: Uri.parse(href),
                ),
              );
            },
          ),
  );
}
