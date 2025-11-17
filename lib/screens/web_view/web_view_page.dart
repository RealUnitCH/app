import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/styles/styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

class WebViewRouteParams {
  final String title;
  final Uri url;

  const WebViewRouteParams({required this.title, required this.url});
}

class WebViewPage extends StatelessWidget {
  WebViewPage(WebViewRouteParams params, {super.key})
      : _title = params.title,
        _url = params.url;

  final String _title;
  final Uri _url;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: CupertinoNavigationBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: RealUnitColors.realUnitBlack,
              size: 24,
            ),
          ),
          middle: Text(
            _title,
            style: kPageTitleTextStyle,
          ),
          border: null,
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
          resourceCustomSchemes: ["deuro-wallet"],
        ),
        initialUrlRequest: URLRequest(url: WebUri.uri(uri)),
        onLoadStart: (controller, url) {
          if (url?.scheme == "deuro-wallet") {
            controller.stopLoading();
            context.pop("$url");
          }
        },
      );
}
