import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_bind_result_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/setup/routing/boot_navigation.dart';
import 'package:realunit_wallet/setup/routing/referral_bind.dart';
import 'package:realunit_wallet/setup/routing/referral_pending_code.dart';
import 'package:realunit_wallet/setup/routing/routes/app_link_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helper/helper.dart';

class _MockPinAuthCubit extends Mock implements PinAuthCubit {}

// Invite and promo links only hand over their code. Whatever path they carry,
// a warm open keeps the current screen, locked or unlocked. `/settings` stands
// in for any in-app route a link path could name.
void main() {
  late _MockPinAuthCubit pinAuthCubit;

  const inviteLinks = <String, String>{
    'custom scheme': 'realunit-wallet://invite/settings',
    'https': 'https://realunit.app/settings?app-argument=https://realunit.app/invite/AB12CD',
    'intent':
        'intent://realunit.app/settings?app-argument=https://realunit.app/invite/AB12CD#Intent;scheme=https;end',
    'android-app':
        'android-app://swiss.realunit.app/settings?app-argument=https://realunit.app/invite/AB12CD',
    'ios-app': 'ios-app://6759720010/settings?app-argument=https://realunit.app/invite/AB12CD',
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await clearPendingReferralCode();
    debugResetBindInFlight();
    pinAuthCubit = _MockPinAuthCubit();
    GetIt.instance.registerSingleton<PinAuthCubit>(pinAuthCubit);
    // An unlocked bind stays in flight: no dialog, the code is taken.
    final service = MockRealUnitReferralService();
    when(
      () => service.bind(code: any(named: 'code')),
    ).thenAnswer((_) => Completer<ReferralBindResultDto>().future);
    GetIt.instance.registerSingleton<RealUnitReferralService>(service);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await clearPendingReferralCode();
    debugResetBindInFlight();
  });

  void pinState({required bool isPinSetup, required bool isPinVerified}) => when(
    () => pinAuthCubit.state,
  ).thenReturn(PinAuthState(isPinSetup: isPinSetup, isPinVerified: isPinVerified));

  Future<GoRouter> pump(WidgetTester tester, {required String initial}) async {
    late final GoRouter router;
    router = GoRouter(
      initialLocation: initial,
      redirect: (context, state) => appLinkSchemeRedirect(
        state,
        effectiveLocation(router.routerDelegate.currentConfiguration),
        router,
      ),
      onException: appLinkOnException,
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('HOME', key: Key('home'))),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: Text('DASH', key: Key('dashboard'))),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const Scaffold(body: Text('SET', key: Key('settings'))),
        ),
        GoRoute(
          path: '/verifyPin',
          builder: (_, _) => const Scaffold(body: Text('VERIFY', key: Key('verifyPin'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  for (final MapEntry(key: kind, value: link) in inviteLinks.entries) {
    testWidgets('$kind invite link keeps the unlocked app on its screen', (tester) async {
      pinState(isPinSetup: true, isPinVerified: true);
      final router = await pump(tester, initial: '/dashboard');

      router.go(link);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboard')), findsOneWidget);
      expect(find.byKey(const Key('settings')), findsNothing);
      verify(() => GetIt.instance<RealUnitReferralService>().bind(code: any(named: 'code')));
    });

    testWidgets('$kind invite link keeps the locked app on the PIN prompt', (tester) async {
      pinState(isPinSetup: true, isPinVerified: false);
      final router = await pump(tester, initial: '/verifyPin');

      router.go(link);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('verifyPin')), findsOneWidget);
      expect(find.byKey(const Key('settings')), findsNothing);
      expect(peekPendingReferralCodeSync(), isNotNull);
    });

    testWidgets('$kind invite link keeps a pushed screen and its back stack', (tester) async {
      pinState(isPinSetup: true, isPinVerified: false);
      final router = await pump(tester, initial: '/dashboard');
      unawaited(router.push('/verifyPin'));
      await tester.pumpAndSettle();

      router.go(link);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('verifyPin')), findsOneWidget);
      expect(router.canPop(), isTrue);
    });

    testWidgets('$kind invite link on a cold start boots to the normal entry', (tester) async {
      pinState(isPinSetup: true, isPinVerified: false);
      final router = await pump(tester, initial: link);

      expect(router.routerDelegate.currentConfiguration.uri.path, appLinkColdStartLocation);
      expect(find.byKey(const Key('home')), findsOneWidget);
      expect(peekPendingReferralCodeSync(), isNotNull);
    });
  }

  testWidgets('https link without an invite code keeps the app on its screen', (tester) async {
    pinState(isPinSetup: true, isPinVerified: true);
    final router = await pump(tester, initial: '/dashboard');

    router.go('https://realunit.app/settings');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('dashboard')), findsOneWidget);
    expect(find.byKey(const Key('settings')), findsNothing);
  });

  testWidgets('https link without an invite code on a cold start boots to the normal entry', (
    tester,
  ) async {
    pinState(isPinSetup: true, isPinVerified: false);
    final router = await pump(tester, initial: 'https://realunit.app/settings');

    expect(router.routerDelegate.currentConfiguration.uri.path, appLinkColdStartLocation);
    expect(find.byKey(const Key('settings')), findsNothing);
  });

  test('every invite link of this file carries an invite code', () {
    for (final link in inviteLinks.values) {
      expect(extractReferralInviteCode(Uri.parse(link)), isNotNull, reason: link);
    }
  });
}
