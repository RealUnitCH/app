import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/setup/routing/router_config.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/pin_routes.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';

import '../../helper/helper.dart';

class _MockPinAuthCubit extends Mock implements PinAuthCubit {}

// Runs the top-level redirect of the production router, the one every page
// change passes, for a direct navigation to a protected route.
void main() {
  late _MockPinAuthCubit pinAuthCubit;
  late MockHomeBloc homeBloc;
  late BuildContext context;

  setUp(() {
    pinAuthCubit = _MockPinAuthCubit();
    homeBloc = MockHomeBloc();
    when(() => homeBloc.state).thenReturn(const HomeState(hasWallet: true));
    GetIt.instance
      ..registerSingleton<PinAuthCubit>(pinAuthCubit)
      ..registerSingleton<HomeBloc>(homeBloc);
  });

  tearDown(() => GetIt.instance.reset());

  void pinState({required bool isPinSetup, required bool isPinVerified}) => when(
    () => pinAuthCubit.state,
  ).thenReturn(PinAuthState(isPinSetup: isPinSetup, isPinVerified: isPinVerified));

  Future<String?> redirectFor(String routeName) async {
    final configuration = routerConfig.configuration;
    final location = configuration.namedLocation(routeName);
    final state = GoRouterState(
      configuration,
      uri: Uri.parse(location),
      matchedLocation: location,
      fullPath: location,
      pathParameters: const {},
      pageKey: const ValueKey<String>('redirect'),
    );
    return configuration.topRedirect(context, state);
  }

  Future<void> captureContext(WidgetTester tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
  }

  testWidgets('a locked app answers a page change with the PIN prompt', (tester) async {
    await captureContext(tester);
    pinState(isPinSetup: true, isPinVerified: false);

    for (final routeName in [AppRoutes.dashboard, SettingsRoutes.settings, SettingsRoutes.seed]) {
      expect(
        await redirectFor(routeName),
        routerConfig.configuration.namedLocation(PinRoutes.verify),
        reason: routeName,
      );
    }
  });

  testWidgets('the PIN setup does not open while a PIN is set', (tester) async {
    await captureContext(tester);
    pinState(isPinSetup: true, isPinVerified: true);

    expect(await redirectFor(PinRoutes.setup), isNotNull);
  });

  testWidgets('the recovery phrase does not open without a fresh PIN', (tester) async {
    await captureContext(tester);
    pinState(isPinSetup: true, isPinVerified: true);

    expect(await redirectFor(SettingsRoutes.seed), isNotNull);
  });

  testWidgets('the PIN change does not open without a fresh PIN', (tester) async {
    await captureContext(tester);
    pinState(isPinSetup: true, isPinVerified: true);

    expect(await redirectFor(SettingsRoutes.changePin), isNotNull);
  });

  testWidgets('an unlocked app opens ordinary pages', (tester) async {
    await captureContext(tester);
    pinState(isPinSetup: true, isPinVerified: true);

    expect(await redirectFor(AppRoutes.dashboard), isNull);
    expect(await redirectFor(SettingsRoutes.settings), isNull);
  });

  testWidgets('the PIN setup opens while no PIN is set', (tester) async {
    await captureContext(tester);
    pinState(isPinSetup: false, isPinVerified: false);

    expect(await redirectFor(PinRoutes.setup), isNull);
  });
}
