import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/packages/utils/device_info.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';
import 'package:url_launcher/url_launcher.dart';

class TextLinkSpan {
  static TextSpan link(
    BuildContext context, {
    required String text,
    required Uri uri,
    TextStyle? style,
  }) {
    return TextSpan(
      text: text,
      style: style ?? const TextStyle(decoration: TextDecoration.underline),
      recognizer: TapGestureRecognizer()
        ..onTap = () async {
          await _launchLink(context, text, uri);
        },
    );
  }

  static Future<void> _launchLink(
    BuildContext context,
    String title,
    Uri uri,
  ) async {
    if (!await canLaunchUrl(uri)) return;

    if (DeviceInfo.instance.isMobile) {
      if (!context.mounted) return;
      await context.push(
        '/webView',
        extra: WebViewRouteParams(title: title, url: uri),
      );
    } else {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
