import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewRouteParams {
  final String title;
  final Uri url;
  final bool showExternalBrowserButton;

  const WebViewRouteParams({
    required this.title,
    required this.url,
    this.showExternalBrowserButton = false,
  });
}

class WebViewPage extends StatelessWidget {
  WebViewPage(WebViewRouteParams params, {super.key})
    : _title = params.title,
      _url = params.url,
      _showExternalBrowserButton = params.showExternalBrowserButton;

  final String _title;
  final Uri _url;
  final bool _showExternalBrowserButton;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: RealUnitColors.realUnitBlack,
          size: 24,
        ),
      ),
      title: Text(
        _title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: RealUnitColors.realUnitBlack,
          fontWeight: .w700,
        ),
      ),
      actions: [
        if (_showExternalBrowserButton)
          IconButton(
            onPressed: () => launchUrl(_url, mode: LaunchMode.externalApplication),
            icon: const Icon(
              Icons.open_in_new_outlined,
              color: RealUnitColors.realUnitBlack,
              size: 24,
            ),
          ),
      ],
    ),
    body: WebViewPageBody(uri: _url),
  );
}

class WebViewPageBody extends StatelessWidget {
  const WebViewPageBody({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) => InAppWebView(
    initialSettings: InAppWebViewSettings(
      transparentBackground: true,
    ),
    initialUrlRequest: URLRequest(
      url: WebUri.uri(uri),
    ),
  );
}
