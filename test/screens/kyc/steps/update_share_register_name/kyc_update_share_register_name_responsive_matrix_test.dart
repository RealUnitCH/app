// Responsive matrix for the share-register name page. Same gate as the
// link-wallet matrix: no overflow, and the CTA is fully tappable.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/registration/kyc/kyc_personal_data.dart';
import 'package:realunit_wallet/packages/service/dfx/models/user/dto/real_unit_user_data_dto.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/cubits/kyc_update_share_register_name_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/cubits/kyc_update_share_register_name_state.dart';
import 'package:realunit_wallet/screens/kyc/steps/update_share_register_name/kyc_update_share_register_name_page.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../../../helper/helper.dart';

class _MockKycCubit extends MockCubit<KycState> implements KycCubit {}

class _MockNameCubit extends MockCubit<KycUpdateShareRegisterNameState>
    implements KycUpdateShareRegisterNameCubit {}

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

Future<void> _pumpMatrixPage(
  WidgetTester tester, {
  required Widget widget,
  required MatrixCell cell,
}) async {
  await tester.binding.setSurfaceSize(cell.device.size);
  addTearDown(() async => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MediaQuery(
      data: cell.mediaQuery,
      child: MaterialApp(
        theme: realUnitTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: widget,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  group(
    '$KycUpdateShareRegisterNameView responsive matrix (full device × textScale)',
    () {
      late _MockNameCubit nameCubit;
      late _MockKycCubit kycCubit;

      setUp(() {
        nameCubit = _MockNameCubit();
        kycCubit = _MockKycCubit();
        when(() => nameCubit.state).thenReturn(
          const KycUpdateShareRegisterNameReady(_userData, _shareRegisterName),
        );
        when(() => kycCubit.state).thenReturn(const KycInitial());
        when(() => kycCubit.checkKyc()).thenAnswer((_) async {});
        when(
          () => nameCubit.submit(
            shareRegisterNameFailed: any(named: 'shareRegisterNameFailed'),
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

      for (final cell in kFullResponsiveMatrix) {
        testWidgets('update_share_register_name · ${cell.id}', (tester) async {
          await withTargetPlatform(cell.device.platform, () async {
            await expectNoLayoutOverflow(
              tester,
              () async {
                await _pumpMatrixPage(tester, widget: buildSubject(), cell: cell);
              },
              reason: 'overflow on update_share_register_name / ${cell.label}',
            );

            await expectFullyTappable(
              tester,
              find.byType(AppFilledButton),
              within: find.byType(KycUpdateShareRegisterNameView),
              reason: 'update_share_register_name / ${cell.label}: CTA not tappable',
            );
          });
        });
      }
    },
  );

  group(
    '$KycUpdateShareRegisterNamePage missing data responsive matrix '
    '(full device × textScale)',
    () {
      late _MockKycCubit kycCubit;

      setUp(() {
        kycCubit = _MockKycCubit();
        when(() => kycCubit.state).thenReturn(const KycInitial());
        when(() => kycCubit.checkKyc()).thenAnswer((_) async {});
      });

      Widget buildSubject() => BlocProvider<KycCubit>.value(
        value: kycCubit,
        child: const KycUpdateShareRegisterNamePage(
          userData: null,
          shareRegisterName: null,
        ),
      );

      for (final cell in kFullResponsiveMatrix) {
        testWidgets('update_share_register_name_missing · ${cell.id}', (tester) async {
          await withTargetPlatform(cell.device.platform, () async {
            await expectNoLayoutOverflow(
              tester,
              () async {
                await _pumpMatrixPage(tester, widget: buildSubject(), cell: cell);
              },
              reason: 'overflow on update_share_register_name_missing / ${cell.label}',
            );

            await expectFullyTappable(
              tester,
              find.byType(AppFilledButton),
              within: find.byType(KycUpdateShareRegisterNamePage),
              reason: 'update_share_register_name_missing / ${cell.label}: CTA not tappable',
            );
          });
        });
      }
    },
  );
}
