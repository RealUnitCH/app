import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_name/cubit/settings_edit_name_cubit.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_name/settings_edit_name_page.dart';

import '../../../helper/helper.dart';

class _MockSettingsEditNameCubit extends MockCubit<SettingsEditNameState>
    implements SettingsEditNameCubit {}

class _MockDfxKycService extends Mock implements DfxKycService {}

void main() {
  const phoneConstraints = BoxConstraints.tightFor(width: 390, height: 844);

  late _MockSettingsEditNameCubit cubit;

  setUp(() {
    cubit = _MockSettingsEditNameCubit();
    when(() => cubit.state).thenReturn(const SettingsEditNameReady('url'));
  });

  setUpAll(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<DfxKycService>(_MockDfxKycService());
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('$SettingsEditNamePage', () {
    goldenTest(
      'default ready state',
      fileName: 'settings_edit_name_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        BlocProvider<SettingsEditNameCubit>.value(
          value: cubit,
          child: const SettingsEditNameView(),
        ),
      ),
    );
  });
}
