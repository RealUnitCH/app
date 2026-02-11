import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/cubits/kyc_ident/kyc_ident_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/ident/kyc_ident_page.dart';

import '../../../helper/pump_app.dart';

class MockKycIdentCubit extends MockCubit<KycIdentState> implements KycIdentCubit {}

class MockKycCubit extends MockCubit<KycState> implements KycCubit {}

void main() {
  late KycIdentCubit kycIdentCubit;
  late KycCubit kycCubit;
  final accessToken = 'abcdef';

  setUp(() {
    kycIdentCubit = MockKycIdentCubit();
    kycCubit = MockKycCubit();

    when(() => kycIdentCubit.state).thenReturn(const KycIdentInitial());
    when(() => kycCubit.state).thenReturn(const KycInitial());
    when(() => kycCubit.checkKyc()).thenAnswer((_) => Future.value());
  });

  Widget buildSubject(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: kycIdentCubit),
        BlocProvider.value(value: kycCubit),
      ],
      child: child,
    );
  }

  group('$KycIdentPage', () {
    testWidgets('renders $KycIdentView', (tester) async {
      await tester.pumpApp(
        KycIdentPage(
          accessToken: accessToken,
        ),
      );

      expect(find.byType(KycIdentView), findsOne);
    });
  });

  group('$KycIdentView', () {
    testWidgets('is initially rendered correctly', (tester) async {
      await tester.pumpApp(buildSubject(KycIdentView(accessToken: accessToken)));

      expect(find.byType(Image), findsOne);
      expect(find.byType(FilledButton), findsOne);
    });
  });

  group('$BlocListener', () {
    testWidgets('triggers checkKyc if ident was successful', (tester) async {
      whenListen(
        kycIdentCubit,
        Stream.fromIterable([
          const KycIdentSuccess(),
        ]),
        initialState: const KycIdentInitial(),
      );

      await tester.pumpApp(buildSubject(KycIdentView(accessToken: accessToken)));
      await tester.pump();

      verify(() => kycCubit.checkKyc()).called(1);
    });

    testWidgets('shows Snackbar if ident failed', (tester) async {
      whenListen(
        kycIdentCubit,
        Stream.fromIterable([
          const KycIdentFailure(
            status: FailureStatus.finallyRejected,
            errorMessage: 'Invalid verification code',
          ),
        ]),
        initialState: const KycIdentInitial(),
      );

      await tester.pumpApp(buildSubject(KycIdentView(accessToken: accessToken)));
      await tester.pump();

      expect(find.byType(SnackBar), findsOne);
    });
  });
}
