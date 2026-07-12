import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/kyc/cubits/kyc/kyc_cubit.dart';
import 'package:realunit_wallet/screens/kyc/subpages/kyc_merge_processing_page.dart';

import '../../../helper/helper.dart';

class _MockKycCubit extends MockCubit<KycState> implements KycCubit {}

void main() {
  late _MockKycCubit kycCubit;

  setUp(() {
    kycCubit = _MockKycCubit();
    when(() => kycCubit.state).thenReturn(const KycInitial());
  });

  group('$KycMergeProcessingPage', () {
    goldenTest(
      'default state',
      fileName: 'kyc_merge_processing_page_default',
      constraints: phoneConstraints,
      // The waiting screen renders a CupertinoActivityIndicator, which animates
      // indefinitely. The default precacheImages pump ends in pumpAndSettle and
      // would time out; pumpOnce freezes the spinner at its first frame so the
      // baseline is deterministic across regenerations (same technique as
      // connect_bitbox_page_connecting).
      pumpBeforeTest: pumpOnce,
      builder: () => wrapForGolden(
        BlocProvider<KycCubit>.value(
          value: kycCubit,
          child: const KycMergeProcessingPage(),
        ),
      ),
    );
  });
}
