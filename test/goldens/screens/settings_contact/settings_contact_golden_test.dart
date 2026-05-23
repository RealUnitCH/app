import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/settings_contact/cubit/settings_contact_cubit.dart';
import 'package:realunit_wallet/screens/settings_contact/settings_contact_page.dart';

import '../../../helper/helper.dart';

class _MockSettingsContactCubit extends MockCubit<SettingsContactState>
    implements SettingsContactCubit {}

class _MockDfxKycService extends Mock implements DfxKycService {}

void main() {
  const phoneConstraints = BoxConstraints.tightFor(width: 390, height: 844);

  late _MockSettingsContactCubit contactCubit;

  setUp(() {
    contactCubit = _MockSettingsContactCubit();
    when(() => contactCubit.state).thenReturn(
      const SettingsContactSuccess(supportAvailable: true),
    );
  });

  setUpAll(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<DfxKycService>(_MockDfxKycService());
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('$SettingsContactPage', () {
    goldenTest(
      'default state with support available',
      fileName: 'settings_contact_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        BlocProvider<SettingsContactCubit>.value(
          value: contactCubit,
          child: const SettingsContactView(),
        ),
      ),
    );
  });
}
