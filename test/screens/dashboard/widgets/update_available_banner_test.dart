import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/client_policy/real_unit_client_policy.dart';
import 'package:realunit_wallet/packages/utils/marketing_version.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/update_available_banner.dart';
import 'package:realunit_wallet/screens/update_required/bloc/client_policy_cubit.dart';
import 'package:realunit_wallet/widgets/outlined_tile.dart';

import '../../../helper/helper.dart';

class MockClientPolicyCubit extends MockCubit<ClientPolicyState>
    implements ClientPolicyCubit {}

void main() {
  group('$UpdateAvailableBanner', () {
    testWidgets('hides when ClientPolicyCubit is not provided', (tester) async {
      await tester.pumpApp(
        const Scaffold(body: UpdateAvailableBanner()),
      );

      expect(find.byType(OutlinedTile), findsNothing);
    });

    testWidgets('hides when the banner is not soft', (tester) async {
      final cubit = MockClientPolicyCubit();
      const state = ClientPolicyLoaded(
        RealUnitClientPolicy(severity: ClientPolicySeverity.hard),
      );
      when(() => cubit.state).thenReturn(state);
      when(() => cubit.showSoftBanner).thenReturn(false);
      whenListen(
        cubit,
        const Stream<ClientPolicyState>.empty(),
        initialState: state,
      );

      await tester.pumpApp(
        Scaffold(
          body: BlocProvider<ClientPolicyCubit>.value(
            value: cubit,
            child: const UpdateAvailableBanner(),
          ),
        ),
      );

      expect(find.byType(OutlinedTile), findsNothing);
    });

    testWidgets(
      'shows when loaded with a soft policy and showSoftBanner is true',
      (tester) async {
        final cubit = MockClientPolicyCubit();
        const state = ClientPolicyLoaded(
          RealUnitClientPolicy(
            severity: ClientPolicySeverity.soft,
            latestVersion: '1.4.0',
          ),
        );
        when(() => cubit.state).thenReturn(state);
        when(() => cubit.showSoftBanner).thenReturn(true);
        whenListen(
          cubit,
          const Stream<ClientPolicyState>.empty(),
          initialState: state,
        );

        await tester.pumpApp(
          Scaffold(
            body: BlocProvider<ClientPolicyCubit>.value(
              value: cubit,
              child: const UpdateAvailableBanner(),
            ),
          ),
        );

        expect(find.byType(OutlinedTile), findsOneWidget);
        expect(
          tester.widget<OutlinedTile>(find.byType(OutlinedTile)).title,
          isNotEmpty,
        );
      },
    );
  });
}
