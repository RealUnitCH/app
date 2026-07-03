import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/settings_security/cubits/settings_security_cubit.dart';
import 'package:realunit_wallet/screens/settings_security/settings_security_page.dart';

import '../../../helper/helper.dart';

class _MockSettingsSecurityCubit extends MockCubit<SettingsSecurityState>
    implements SettingsSecurityCubit {}

void main() {
  group('$SettingsSecurityPage', () {
    goldenTest(
      'default state (biometrics supported and enabled)',
      fileName: 'settings_security_page_default',
      constraints: phoneConstraints,
      builder: () {
        final cubit = _MockSettingsSecurityCubit();
        when(() => cubit.state).thenReturn(
          const SettingsSecurityState(
            biometricSupported: true,
            biometricEnabled: true,
          ),
        );
        return wrapForGolden(
          BlocProvider<SettingsSecurityCubit>.value(
            value: cubit,
            child: const SettingsSecurityView(),
          ),
        );
      },
    );
  });
}
