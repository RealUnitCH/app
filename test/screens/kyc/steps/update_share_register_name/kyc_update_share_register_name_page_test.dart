import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_page.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_view.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/cubits/kyc_update_share_register_name_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/cubits/kyc_update_share_register_name_state.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/kyc_update_share_register_name_page.dart';

class _MockKycUpdateShareRegisterNameCubit
    extends MockCubit<KycUpdateShareRegisterNameState>
    implements KycUpdateShareRegisterNameCubit {}

class _MockKycCubit extends MockCubit<KycState> implements KycCubit {}

class _MockBitboxService extends Mock implements BitboxService {}

class _MockWalletService extends Mock implements WalletService {}

class _MockDfxKycService extends Mock implements DfxKycService {}

class _MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class _FakeBitboxWallet extends Fake implements BitboxWallet {}

const _kycData = KycPersonalData(
  accountType: KycAccountType.personal,
  firstName: 'Ada',
  lastName: 'Lovelace',
  phone: '+41790000000',
  address: KycAddress(street: 'S', zip: '8000', city: 'Zurich', country: 41),
);

const _userData = RealUnitUserDataDto(
  email: 'ada@example.com',
  name: 'Ada Lovelace',
  type: 'HUMAN',
  phoneNumber: '+41790000000',
  birthday: '1815-12-10',
  nationality: 'CH',
  addressStreet: 'S',
  addressPostalCode: '8000',
  addressCity: 'Zurich',
  addressCountry: 'CH',
  swissTaxResidence: true,
  lang: 'de',
  kycData: _kycData,
);

const _shareRegisterName = 'Ada Lovelace';

void main() {
  late _MockKycUpdateShareRegisterNameCubit nameCubit;
  late _MockKycCubit kycCubit;
  late _MockHomeBloc homeBloc;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(SyncWalletServicesEvent(_FakeBitboxWallet()));
    final getIt = GetIt.instance;

    // ConnectBitboxPage (opened by the BitboxRequired listener) builds a real
    // ConnectBitboxCubit off these getIt dependencies. An empty device list
    // keeps the connect sheet parked in its idle scanning state.
    final bitboxService = _MockBitboxService();
    when(() => bitboxService.getAllUsbDevices()).thenAnswer((_) async => <sdk.BitboxDevice>[]);
    when(() => bitboxService.startScan()).thenAnswer((_) async => false);
    getIt.registerSingleton<BitboxService>(bitboxService);
    getIt.registerSingleton<WalletService>(_MockWalletService());
    getIt.registerSingleton<DfxKycService>(_MockDfxKycService());
  });

  tearDownAll(() async => await GetIt.instance.reset());

  setUp(() {
    nameCubit = _MockKycUpdateShareRegisterNameCubit();
    kycCubit = _MockKycCubit();
    homeBloc = _MockHomeBloc();
    when(() => nameCubit.state).thenReturn(
      const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
    );
    when(() => kycCubit.state).thenReturn(const KycInitial());
    when(() => kycCubit.checkKyc()).thenAnswer((_) async {});
    when(
      () => nameCubit.submit(
        shareRegisterNameFailed: any(named: 'shareRegisterNameFailed'),
        shareRegisterNameSendFailed: any(named: 'shareRegisterNameSendFailed'),
        registrationDateUnavailable: any(named: 'registrationDateUnavailable'),
        signingCancelled: any(named: 'signingCancelled'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => nameCubit.retrySubmit(
        shareRegisterNameFailed: any(named: 'shareRegisterNameFailed'),
        shareRegisterNameSendFailed: any(named: 'shareRegisterNameSendFailed'),
        registrationDateUnavailable: any(named: 'registrationDateUnavailable'),
        signingCancelled: any(named: 'signingCancelled'),
      ),
    ).thenAnswer((_) async {});
  });

  Widget buildSubject() => MultiBlocProvider(
    providers: [
      BlocProvider<KycCubit>.value(value: kycCubit),
      BlocProvider<KycUpdateShareRegisterNameCubit>.value(value: nameCubit),
    ],
    child: const KycUpdateShareRegisterNameView(shareRegisterName: _shareRegisterName),
  );

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: buildSubject(),
    ),
  );

  group('$KycUpdateShareRegisterNameView', () {
    testWidgets('tapping the CTA submits with the localized copy', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      verify(
        () => nameCubit.submit(
          shareRegisterNameFailed: any(named: 'shareRegisterNameFailed'),
          shareRegisterNameSendFailed: any(named: 'shareRegisterNameSendFailed'),
          registrationDateUnavailable: any(named: 'registrationDateUnavailable'),
          signingCancelled: any(named: 'signingCancelled'),
        ),
      ).called(1);
    });

    testWidgets('Success triggers KycCubit.checkKyc', (tester) async {
      whenListen(
        nameCubit,
        Stream.fromIterable([const KycUpdateShareRegisterNameSuccess()]),
        initialState: const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
      );

      await pumpApp(tester);
      await tester.pump();

      verify(() => kycCubit.checkKyc()).called(1);
    });

    testWidgets('Failure shows a SnackBar with the failure text', (tester) async {
      whenListen(
        nameCubit,
        Stream.fromIterable([const KycUpdateShareRegisterNameFailure('boom')]),
        initialState: const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
      );

      await pumpApp(tester);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
    });
  });

  group('$KycUpdateShareRegisterNameView BitBox connect sheet', () {
    void emitBitboxRequired() => whenListen(
      nameCubit,
      Stream.fromIterable([
        const KycUpdateShareRegisterNameBitboxRequired(_userData, _shareRegisterName),
      ]),
      initialState: const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
    );

    // Opens, then settles, the connect sheet. Popping the modal route disposes
    // the real ConnectBitboxCubit, which cancels its periodic scan timer — so
    // every test must close the sheet to avoid a pending-timer failure.
    Future<void> pumpUntilSheetOpen(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.pump(); // deliver BitboxRequired to the listener
      await tester.pump(const Duration(milliseconds: 350)); // sheet open animation
    }

    NavigatorState sheetNavigator(WidgetTester tester) =>
        Navigator.of(tester.element(find.byType(ConnectBitboxPage)));

    testWidgets('BitboxRequired opens the ConnectBitboxPage connect sheet', (tester) async {
      emitBitboxRequired();

      await pumpUntilSheetOpen(tester);

      expect(find.byType(ConnectBitboxPage), findsOneWidget);

      sheetNavigator(tester).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('a successful connect (sheet returns true) retries the submit', (tester) async {
      emitBitboxRequired();

      await pumpUntilSheetOpen(tester);
      expect(find.byType(ConnectBitboxPage), findsOneWidget);

      sheetNavigator(tester).pop(true);
      await tester.pumpAndSettle();

      verify(
        () => nameCubit.retrySubmit(
          shareRegisterNameFailed: any(named: 'shareRegisterNameFailed'),
          shareRegisterNameSendFailed: any(named: 'shareRegisterNameSendFailed'),
          registrationDateUnavailable: any(named: 'registrationDateUnavailable'),
          signingCancelled: any(named: 'signingCancelled'),
        ),
      ).called(1);
    });

    testWidgets('onFinish syncs the wallet and retries the submit', (tester) async {
      emitBitboxRequired();

      // `onFinish` calls `context.pop(true)` (go_router), so host the view in a
      // GoRouter stack; with the sheet route on top, canPop is true.
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => MultiBlocProvider(
              providers: [
                BlocProvider<KycCubit>.value(value: kycCubit),
                BlocProvider<KycUpdateShareRegisterNameCubit>.value(value: nameCubit),
                BlocProvider<HomeBloc>.value(value: homeBloc),
              ],
              child: const KycUpdateShareRegisterNameView(
                shareRegisterName: _shareRegisterName,
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
        ),
      );
      await tester.pump(); // deliver BitboxRequired to the listener
      await tester.pump(const Duration(milliseconds: 350)); // sheet open animation
      expect(find.byType(ConnectBitboxView), findsOneWidget);

      // ConnectBitboxPage forwards the page's onFinish straight to the view;
      // invoke it exactly as the connect flow does on BitboxFinishSetup.
      final view = tester.widget<ConnectBitboxView>(find.byType(ConnectBitboxView));
      view.onFinish(_FakeBitboxWallet());
      await tester.pumpAndSettle();

      verify(() => homeBloc.add(any(that: isA<SyncWalletServicesEvent>()))).called(1);
      verify(
        () => nameCubit.retrySubmit(
          shareRegisterNameFailed: any(named: 'shareRegisterNameFailed'),
          shareRegisterNameSendFailed: any(named: 'shareRegisterNameSendFailed'),
          registrationDateUnavailable: any(named: 'registrationDateUnavailable'),
          signingCancelled: any(named: 'signingCancelled'),
        ),
      ).called(1);
    });

    testWidgets('sheet returning false does not retry', (tester) async {
      emitBitboxRequired();

      await pumpUntilSheetOpen(tester);

      sheetNavigator(tester).pop(false);
      await tester.pumpAndSettle();

      verifyNever(
        () => nameCubit.retrySubmit(
          shareRegisterNameFailed: any(named: 'shareRegisterNameFailed'),
          shareRegisterNameSendFailed: any(named: 'shareRegisterNameSendFailed'),
          registrationDateUnavailable: any(named: 'registrationDateUnavailable'),
          signingCancelled: any(named: 'signingCancelled'),
        ),
      );
    });

    testWidgets('dismissing the sheet without a result does not retry', (tester) async {
      emitBitboxRequired();

      await pumpUntilSheetOpen(tester);

      // Back button / scrim tap pops with a null result.
      sheetNavigator(tester).pop();
      await tester.pumpAndSettle();

      verifyNever(
        () => nameCubit.retrySubmit(
          shareRegisterNameFailed: any(named: 'shareRegisterNameFailed'),
          shareRegisterNameSendFailed: any(named: 'shareRegisterNameSendFailed'),
          registrationDateUnavailable: any(named: 'registrationDateUnavailable'),
          signingCancelled: any(named: 'signingCancelled'),
        ),
      );
    });
  });

  group('$KycUpdateShareRegisterNamePage with missing data', () {
    testWidgets('renders the defensive retry page and retries via KycCubit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<KycCubit>.value(
            value: kycCubit,
            child: const KycUpdateShareRegisterNamePage(
              userData: null,
              shareRegisterName: null,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      verify(() => kycCubit.checkKyc()).called(1);
    });
  });
}
