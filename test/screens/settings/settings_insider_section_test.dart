import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings/settings_page.dart';
import 'package:realunit_wallet/screens/settings/widgets/settings_section.dart';

import '../../helper/helper.dart';

void main() {
  late MockSettingsBloc settingsBloc;
  late MockHomeBloc homeBloc;
  late MockSoftwareWallet wallet;
  late MockRealUnitReferralService referral;

  setUp(() async {
    await GetIt.instance.reset();
    settingsBloc = MockSettingsBloc();
    homeBloc = MockHomeBloc();
    wallet = MockSoftwareWallet();
    referral = MockRealUnitReferralService();

    when(() => wallet.walletType).thenReturn(WalletType.software);
    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(() => homeBloc.state).thenReturn(HomeState(openWallet: wallet));
    when(() => referral.getSummary()).thenAnswer(
      (_) async => const ReferralSummaryDto(
        eligible: false,
        termsAccepted: false,
        openCount: 0,
        creditedCount: 0,
        realuSum: 0,
        chfSum: 0,
      ),
    );
    GetIt.instance.registerSingleton<SettingsBloc>(settingsBloc);
    GetIt.instance.registerSingleton<RealUnitReferralService>(referral);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Future<void> pumpSettings(WidgetTester tester) {
    return tester.pumpWidget(
      wrapForGolden(
        BlocProvider<HomeBloc>.value(
          value: homeBloc,
          child: const SettingsPage(unavailablePollInterval: Duration.zero),
        ),
      ),
    );
  }

  List<String> firstSectionTitles(WidgetTester tester) {
    final section = tester.widget<SettingsSections>(find.byType(SettingsSections).first);
    return section.settings.map((option) => option.title).toList();
  }

  testWidgets('locked: no insider section title and no Pay switch', (tester) async {
    await pumpSettings(tester);
    await tester.pumpAndSettle();

    expect(find.text(S.current.settingsInsiderFeatures), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets(
    'unlocked software wallet: header and Pay row appear before Wallet-Sicherung',
    (tester) async {
      when(() => settingsBloc.state)
          .thenReturn(const SettingsState(insiderFeaturesUnlocked: true));

      await pumpSettings(tester);
      await tester.pumpAndSettle();

      expect(find.text(S.current.settingsInsiderFeatures), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(
        firstSectionTitles(tester),
        containsAllInOrder([
          S.current.walletAddress,
          S.current.settingsInsiderFeatures,
          S.current.pay,
          S.current.settingsWalletBackup,
        ]),
      );
    },
  );

  testWidgets('tapping the Pay row dispatches SetInsiderPayEnabledEvent(true) once', (
    tester,
  ) async {
    when(() => settingsBloc.state)
        .thenReturn(const SettingsState(insiderFeaturesUnlocked: true));

    await pumpSettings(tester);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(S.current.pay));
    await tester.tap(find.text(S.current.pay));
    await tester.pump();

    verify(() => settingsBloc.add(const SetInsiderPayEnabledEvent(true))).called(1);
  });

  testWidgets(
    'bitbox wallet + unlocked: header and Pay appear; Wallet-Sicherung stays hidden',
    (tester) async {
      final bitbox = MockBitboxWallet();
      when(() => bitbox.walletType).thenReturn(WalletType.bitbox);
      when(() => homeBloc.state).thenReturn(HomeState(openWallet: bitbox));
      when(() => settingsBloc.state)
          .thenReturn(const SettingsState(insiderFeaturesUnlocked: true));

      await pumpSettings(tester);
      await tester.pumpAndSettle();

      expect(find.text(S.current.settingsInsiderFeatures), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text(S.current.settingsWalletBackup), findsNothing);
      expect(
        firstSectionTitles(tester),
        containsAllInOrder([
          S.current.walletAddress,
          S.current.settingsInsiderFeatures,
          S.current.pay,
        ]),
      );
      expect(
        firstSectionTitles(tester),
        isNot(contains(S.current.settingsWalletBackup)),
      );
    },
  );
}
