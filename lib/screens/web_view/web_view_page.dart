import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewRouteParams {
  final String title;
  final Uri url;
  final bool showDownloadButton;

  const WebViewRouteParams({
    required this.title,
    required this.url,
    this.showDownloadButton = false,
  });
}

class WebViewPage extends StatelessWidget {
  WebViewPage(WebViewRouteParams params, {super.key})
      : _title = params.title,
        _url = params.url,
        _showDownloadButton = params.showDownloadButton;

  final String _title;
  final Uri _url;
  final bool _showDownloadButton;

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
            style: kPageTitleTextStyle,
          ),
          actions: [
            if (_showDownloadButton)
              IconButton(
                onPressed: () => launchUrl(_url, mode: LaunchMode.externalApplication),
                icon: const Icon(
                  Icons.download_rounded,
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
          resourceCustomSchemes: ['deuro-wallet'],
        ),
        initialUrlRequest: URLRequest(url: WebUri.uri(uri)),
        onLoadStart: (controller, url) {
          if (url?.scheme == 'deuro-wallet') {
            controller.stopLoading();
            context.pop('$url');
          }
        },
      );
}
