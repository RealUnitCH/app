import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';

class LegalDocumentParams {
  final String title;
  final String assetBaseName;

  const LegalDocumentParams({
    required this.title,
    required this.assetBaseName,
  });
}

class LegalDocumentPage extends StatefulWidget {
  static const routeName = '/legalDocument';

  final LegalDocumentParams params;

  const LegalDocumentPage({super.key, required this.params});

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  String? _markdownContent;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.params.title),
        ),
        body: _markdownContent == null
            ? const Center(child: CupertinoActivityIndicator())
            : Markdown(
                data: _markdownContent!,
                styleSheet: MarkdownStyleSheet(
                  h2Padding: const EdgeInsets.only(top: 16),
                ),
              ),
      );
}
