import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/screens/receive/receive_page.dart';

import '../../../helper/helper.dart';

class _MockAppStore extends Mock implements AppStore {}

void main() {
  setUpAll(() {
    final getIt = GetIt.instance;
    final appStore = _MockAppStore();
    when(() => appStore.primaryAddress)
        .thenReturn('0xcabd3f4b10a7089986e708d19140bfc98e5880c0');
    getIt.registerSingleton<AppStore>(appStore);
  });

  tearDownAll(() async => GetIt.instance.reset());

  group('$ReceivePage', () {
    goldenTest(
      'default bottom sheet',
      fileName: 'receive_page_default',
      constraints: const BoxConstraints.tightFor(width: 390, height: 844),
      builder: () => wrapForGolden(const ReceivePage()),
    );
  });
}
