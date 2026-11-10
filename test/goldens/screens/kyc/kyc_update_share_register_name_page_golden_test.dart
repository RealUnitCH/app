import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/cubits/kyc_update_share_register_name_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/cubits/kyc_update_share_register_name_state.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/kyc_update_share_register_name_page.dart';

import '../../../helper/helper.dart';

class _MockNameCubit extends MockCubit<KycUpdateShareRegisterNameState>
    implements KycUpdateShareRegisterNameCubit {}

class _MockKycCubit extends MockCubit<KycState> implements KycCubit {}

class _MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class _MockBitboxService extends Mock implements BitboxService {}

class _MockWalletService extends Mock implements WalletService {}

class _MockDfxKycService extends Mock implements DfxKycService {}

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
  addressStreet: 'Bahnhofstrasse 1',
  addressPostalCode: '8000',
  addressCity: 'Zurich',
  addressCountry: 'CH',
  swissTaxResidence: true,
  lang: 'de',
  kycData: _kycData,
);

const _shareRegisterName = 'Ada Lovelace';

const _genericFailure =
    'Das Aktienregister hat die Aktualisierung nicht angenommen. '
    'Bitte versuchen Sie es erneut.';

const _sendFailed =
    'Die Aktualisierung konnte nicht gesendet werden. '
    'Bitte versuchen Sie es erneut.';

const _rejection = 'Der Name stimmt nicht mit dem genehmigten Eintrag überein.';

const _dateUnavailable =
    'Das Registrierungsdatum konnte nicht geladen werden. '
    'Es wurde nichts signiert. Bitte versuchen Sie es erneut.';

const _signingCancelled = 'Signatur abgebrochen — bitte BitBox erneut bestätigen';

void main() {
  late _MockNameCubit nameCubit;
  late _MockKycCubit kycCubit;
  late _MockHomeBloc homeBloc;

  setUp(() {
    nameCubit = _MockNameCubit();
    kycCubit = _MockKycCubit();
    homeBloc = _MockHomeBloc();
    when(() => kycCubit.state).thenReturn(const KycInitial());
    when(() => kycCubit.checkKyc()).thenAnswer((_) async {});
  });

  setUpAll(() {
    final getIt = GetIt.instance;
    final bitboxService = _MockBitboxService();
    when(() => bitboxService.startScan()).thenAnswer((_) async => false);
    when(() => bitboxService.getAllUsbDevices()).thenAnswer((_) async => <sdk.BitboxDevice>[]);
    getIt.registerSingleton<BitboxService>(bitboxService);
    getIt.registerSingleton<WalletService>(_MockWalletService());
    getIt.registerSingleton<DfxKycService>(_MockDfxKycService());
  });

  tearDownAll(() async => GetIt.instance.reset());

  Widget buildView() => wrapForGolden(
    MultiBlocProvider(
      providers: [
        BlocProvider<KycCubit>.value(value: kycCubit),
        BlocProvider<KycUpdateShareRegisterNameCubit>.value(value: nameCubit),
        BlocProvider<HomeBloc>.value(value: homeBloc),
      ],
      child: const KycUpdateShareRegisterNameView(shareRegisterName: _shareRegisterName),
    ),
  );

  group('$KycUpdateShareRegisterNameView', () {
    goldenTest(
      'ready — title, explanation, approved name, idle button',
      fileName: 'kyc_update_share_register_name_page_default',
      constraints: phoneConstraints,
      builder: () {
        when(() => nameCubit.state).thenReturn(
          const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
        );
        return buildView();
      },
    );

    goldenTest(
      'submitting — button loading',
      fileName: 'kyc_update_share_register_name_page_submitting',
      constraints: phoneConstraints,
      pumpBeforeTest: pumpOnce,
      builder: () {
        when(() => nameCubit.state).thenReturn(
          const KycUpdateShareRegisterNameSubmitting(_userData, _shareRegisterName),
        );
        return buildView();
      },
    );

    goldenTest(
      'missing data — failure copy and refresh',
      fileName: 'kyc_update_share_register_name_page_missing_data',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        BlocProvider<KycCubit>.value(
          value: kycCubit,
          child: const KycUpdateShareRegisterNamePage(
            userData: null,
            shareRegisterName: null,
          ),
        ),
      ),
    );

    goldenTest(
      'failure — generic share-register snackbar, button idle',
      fileName: 'kyc_update_share_register_name_page_failure',
      constraints: phoneConstraints,
      pumpBeforeTest: (tester) async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      },
      builder: () {
        whenListen(
          nameCubit,
          Stream<KycUpdateShareRegisterNameState>.value(
            const KycUpdateShareRegisterNameFailure(_genericFailure),
          ),
          initialState: const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
        );
        return buildView();
      },
    );

    goldenTest(
      'send failed — snackbar says the update could not be sent, button idle',
      fileName: 'kyc_update_share_register_name_page_send_failed',
      constraints: phoneConstraints,
      pumpBeforeTest: (tester) async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      },
      builder: () {
        whenListen(
          nameCubit,
          Stream<KycUpdateShareRegisterNameState>.value(
            const KycUpdateShareRegisterNameFailure(_sendFailed),
          ),
          initialState: const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
        );
        return buildView();
      },
    );

    goldenTest(
      'rejection — snackbar with a sentence other than the generic failure',
      fileName: 'kyc_update_share_register_name_page_rejection',
      constraints: phoneConstraints,
      pumpBeforeTest: (tester) async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      },
      builder: () {
        whenListen(
          nameCubit,
          Stream<KycUpdateShareRegisterNameState>.value(
            const KycUpdateShareRegisterNameFailure(_rejection),
          ),
          initialState: const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
        );
        return buildView();
      },
    );

    goldenTest(
      'registration date unavailable — localized red snackbar',
      fileName: 'kyc_update_share_register_name_page_registration_date_unavailable',
      constraints: phoneConstraints,
      pumpBeforeTest: (tester) async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      },
      builder: () {
        whenListen(
          nameCubit,
          Stream<KycUpdateShareRegisterNameState>.value(
            const KycUpdateShareRegisterNameFailure(_dateUnavailable),
          ),
          initialState: const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
        );
        return buildView();
      },
    );

    goldenTest(
      'signing cancelled — localized red snackbar',
      fileName: 'kyc_update_share_register_name_page_signing_cancelled',
      constraints: phoneConstraints,
      pumpBeforeTest: (tester) async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      },
      builder: () {
        whenListen(
          nameCubit,
          Stream<KycUpdateShareRegisterNameState>.value(
            const KycUpdateShareRegisterNameFailure(_signingCancelled),
          ),
          initialState: const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
        );
        return buildView();
      },
    );

    goldenTest(
      'success — centered activity indicator',
      fileName: 'kyc_update_share_register_name_page_success',
      constraints: phoneConstraints,
      pumpBeforeTest: pumpOnce,
      builder: () {
        when(() => nameCubit.state).thenReturn(const KycUpdateShareRegisterNameSuccess());
        return buildView();
      },
    );

    goldenTest(
      'BitBox required — the connect sheet opened over the name page',
      fileName: 'kyc_update_share_register_name_page_bitbox_required',
      constraints: phoneConstraints,
      pumpBeforeTest: (tester) async {
        await tester.pump();
        await tester.pumpAndSettle();
      },
      builder: () {
        whenListen(
          nameCubit,
          Stream.fromIterable([
            const KycUpdateShareRegisterNameBitboxRequired(_userData, _shareRegisterName),
          ]),
          initialState: const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
        );
        return buildView();
      },
    );
  });
}
