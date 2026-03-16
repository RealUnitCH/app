import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/settings_seed/bloc/settings_seed_cubit.dart';
import 'package:realunit_wallet/screens/settings_seed/settings_seed_page.dart';
import 'package:realunit_wallet/screens/settings_seed/settings_seed_view.dart';
import 'package:realunit_wallet/widgets/mnemonic_field.dart';
import 'package:realunit_wallet/widgets/seed_blur_card.dart';

import '../../helper/helper.dart';

class MockSettingsSeedCubit extends MockCubit<SettingsSeedState> implements SettingsSeedCubit {}

class MockAppStore extends Mock implements AppStore {}

class MockWallet extends Mock implements SoftwareWallet {}

void main() {
  late SettingsSeedCubit settingsSeedCubit;
  final AppStore appStore = MockAppStore();
  final SoftwareWallet wallet = MockWallet();

  setUp(() {
    settingsSeedCubit = MockSettingsSeedCubit();

    when(() => settingsSeedCubit.state).thenReturn(
      const SettingsSeedState(
        'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
      ),
    );
    when(() => appStore.wallet).thenReturn(wallet);
    when(() => wallet.seed).thenReturn(
      'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
    );
  });

  void setupDependencyInjection() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<AppStore>(appStore);
  }

  setUpAll(() {
    setupDependencyInjection();
  });

  Widget buildSubject(Widget child) {
    return BlocProvider.value(
      value: settingsSeedCubit,
      child: child,
    );
  }

  group('$SettingsSeedPage', () {
    testWidgets('renders $SettingsSeedView', (tester) async {
      await tester.pumpApp(const SettingsSeedPage());

      expect(find.byType(SettingsSeedView), findsOne);
    });
  });

  group('$SettingsSeedView', () {
    testWidgets('renders initially correctly', (tester) async {
      await tester.pumpApp(buildSubject(const SettingsSeedView()));

      expect(
        find.byWidgetPredicate((Widget widget) => widget is SvgPicture && widget.height == 124),
        findsOne,
      );
      expect(find.byType(SeedBlurCard), findsOne);
    });

    group('$MnemonicReadOnlyField', () {
      testWidgets('is blurred', (tester) async {
        when(() => settingsSeedCubit.state).thenReturn(
          const SettingsSeedState(
            'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
            showSeed: false,
          ),
        );

        await tester.pumpApp(buildSubject(const SettingsSeedView()));

        expect(
          find.byWidgetPredicate((Widget widget) => widget is SeedBlurCard && widget.blur == true),
          findsOne,
        );
      });

      testWidgets('is unblurred', (tester) async {
        when(() => settingsSeedCubit.state).thenReturn(
          const SettingsSeedState(
            'cheese trigger cannon mention judge hire snack sustain annual predict illness celery',
            showSeed: true,
          ),
        );

        await tester.pumpApp(buildSubject(const SettingsSeedView()));

        expect(
          find.byWidgetPredicate((Widget widget) => widget is SeedBlurCard && widget.blur == false),
          findsOne,
        );
      });
    });
  });
}
