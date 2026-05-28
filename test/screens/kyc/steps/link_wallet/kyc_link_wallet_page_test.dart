import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_registration_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/link_wallet/cubits/kyc_link_wallet_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/link_wallet/kyc_link_wallet_page.dart';

import '../../../../helper/helper.dart';

class _MockKycLinkWalletCubit extends MockCubit<KycLinkWalletState>
    implements KycLinkWalletCubit {}

class _MockKycCubit extends MockCubit<KycState> implements KycCubit {}

class _MockAppStore extends Mock implements AppStore {}

class _MockRealUnitWalletService extends Mock implements RealUnitWalletService {}

class _MockRealUnitRegistrationService extends Mock implements RealUnitRegistrationService {}

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

const _debugAddress = '0xfaeefaeefaeefaeefaeefaeefaeefaeefaeeb6a0';

void main() {
  late _MockKycLinkWalletCubit linkCubit;
  late _MockKycCubit kycCubit;

  setUpAll(() {
    registerFallbackValue(_userData);

    final getIt = GetIt.instance;
    final appStore = _MockAppStore();
    when(() => appStore.wallet).thenReturn(DebugWallet(1, 'Test', _debugAddress));
    getIt.registerSingleton<AppStore>(appStore);
    getIt.registerSingleton<RealUnitWalletService>(_MockRealUnitWalletService());
    getIt.registerSingleton<RealUnitRegistrationService>(
      _MockRealUnitRegistrationService(),
    );
  });

  tearDownAll(() async => await GetIt.instance.reset());

  setUp(() {
    linkCubit = _MockKycLinkWalletCubit();
    kycCubit = _MockKycCubit();
    when(() => linkCubit.state).thenReturn(const KycLinkWalletInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
    when(() => kycCubit.checkKyc()).thenAnswer((_) async {});
    when(() => linkCubit.submit(any())).thenAnswer((_) async {});
    when(() => linkCubit.loadUserData()).thenAnswer((_) async {});
  });

  Widget buildSubject() => MultiBlocProvider(
    providers: [
      BlocProvider<KycCubit>.value(value: kycCubit),
      BlocProvider<KycLinkWalletCubit>.value(value: linkCubit),
    ],
    child: const KycLinkWalletView(),
  );

  group('$KycLinkWalletView', () {
    testWidgets('shows CupertinoActivityIndicator while loading', (tester) async {
      when(() => linkCubit.state).thenReturn(const KycLinkWalletLoading());

      await tester.pumpApp(buildSubject());

      expect(find.byType(CupertinoActivityIndicator), findsOne);
    });

    testWidgets('renders the userData name and the current wallet address in Ready', (tester) async {
      when(() => linkCubit.state).thenReturn(const KycLinkWalletReady(_userData));

      await tester.pumpApp(buildSubject());

      expect(find.text(_userData.name), findsOne);
      // hexEip55 of an all-lowercase 0xface…fa address mixes case; assert the
      // 0x prefix is present and the address renders fully so a future change
      // that crops it (e.g. to "0xfaee…b6a0") would fail loud.
      expect(
        find.byWidgetPredicate((w) =>
            w is Text && (w.data?.startsWith('0x') ?? false) && w.data!.length == 42),
        findsOne,
      );
    });

    testWidgets('button triggers cubit.submit with the userData', (tester) async {
      when(() => linkCubit.state).thenReturn(const KycLinkWalletReady(_userData));

      await tester.pumpApp(buildSubject());

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      verify(() => linkCubit.submit(_userData)).called(1);
    });

    testWidgets('button is disabled while Submitting', (tester) async {
      when(() => linkCubit.state).thenReturn(const KycLinkWalletSubmitting(_userData));

      await tester.pumpApp(buildSubject());

      final btn = tester.widget<FilledButton>(find.bySubtype<FilledButton>());
      expect(btn.onPressed, isNull);
    });

    testWidgets('Success state triggers KycCubit.checkKyc', (tester) async {
      whenListen(
        linkCubit,
        Stream.fromIterable([const KycLinkWalletSuccess()]),
        initialState: const KycLinkWalletReady(_userData),
      );

      await tester.pumpApp(buildSubject());
      await tester.pump();

      verify(() => kycCubit.checkKyc()).called(1);
    });

    testWidgets('Failure shows a SnackBar', (tester) async {
      whenListen(
        linkCubit,
        Stream.fromIterable([const KycLinkWalletFailure('boom')]),
        initialState: const KycLinkWalletReady(_userData),
      );

      await tester.pumpApp(buildSubject());
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
    });
  });
}
