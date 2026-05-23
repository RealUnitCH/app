import 'package:alchemist/alchemist.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/screens/settings_network/settings_network_page.dart';

import '../../../helper/helper.dart';

void main() {

  late MockSettingsBloc settingsBloc;

  setUp(() {
    settingsBloc = MockSettingsBloc();
    when(() => settingsBloc.state).thenReturn(const SettingsState());

    final getIt = GetIt.instance;
    if (getIt.isRegistered<SettingsBloc>()) {
      getIt.unregister<SettingsBloc>();
    }
    getIt.registerSingleton<SettingsBloc>(settingsBloc);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('$SettingsNetworkPage', () {
    goldenTest(
      'default state with mainnet selected',
      fileName: 'settings_network_page_default',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(
        BlocProvider<SettingsBloc>.value(
          value: settingsBloc,
          child: SettingsNetworkPage(),
        ),
      ),
    );
  });
}
