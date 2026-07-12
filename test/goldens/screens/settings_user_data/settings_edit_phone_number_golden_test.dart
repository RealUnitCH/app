import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_kyc_service.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_phone_number/cubit/settings_edit_phone_number_cubit.dart';
import 'package:realunit_wallet/screens/settings_user_data/subpages/edit_phone_number/settings_edit_phone_number_page.dart';

import '../../../helper/helper.dart';

class _MockSettingsEditPhoneNumberCubit
    extends MockCubit<SettingsEditPhoneNumberState>
    implements SettingsEditPhoneNumberCubit {}

class _MockDfxKycService extends Mock implements DfxKycService {}

void main() {

  late _MockSettingsEditPhoneNumberCubit cubit;

  setUp(() {
    cubit = _MockSettingsEditPhoneNumberCubit();
    when(() => cubit.state).thenReturn(const SettingsEditPhoneNumberInitial());
  });

  setUpAll(() {
    final getIt = GetIt.instance;
    getIt.registerSingleton<DfxKycService>(_MockDfxKycService());
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  group('$SettingsEditPhoneNumberPage', () {
    goldenTest(
      'default initial state',
      fileName: 'settings_edit_phone_number_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        BlocProvider<SettingsEditPhoneNumberCubit>.value(
          value: cubit,
          child: const SettingsEditPhoneNumberView(),
        ),
      ),
    );
  });
}
