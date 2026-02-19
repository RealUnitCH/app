import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

class LegalPageParams {
  final String title;
  final String assetPath;

  const LegalPageParams({required this.title, required this.assetPath});
}

class LegalPage extends StatefulWidget {
  static const routeName = '/legal';

  const LegalPage({super.key, required this.params});

  final LegalPageParams params;

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
    try {
      final content = await rootBundle.loadString(widget.params.assetPath);
      if (mounted) setState(() => _markdownContent = content);
    } catch (_) {
      if (mounted) setState(() => _markdownContent = '');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(widget.params.title),
    ),
    body: _markdownContent == null
        ? const Center(child: CircularProgressIndicator())
        : Markdown(data: _markdownContent!),
  );
}
