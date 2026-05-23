import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/web_view/web_view_page.dart';

import '../../../helper/helper.dart';

void main() {
  group('$WebViewPage', () {
    goldenTest(
      'default app bar with title',
      fileName: 'web_view_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(
        WebViewPage(
          WebViewRouteParams(
            title: 'RealUnit',
            url: Uri.parse('https://realunit.ch'),
          ),
        ),
      ),
      skip: true,
    );
  });
}
