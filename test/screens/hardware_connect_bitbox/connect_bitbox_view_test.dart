import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/bloc/connect_bitbox_cubit.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/connect_bitbox_view.dart';
import 'package:realunit_wallet/screens/hardware_connect_bitbox/widgets/connect_content.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../helper/helper.dart';

class _MockConnectBitboxCubit extends MockCubit<BitboxConnectionState>
    implements ConnectBitboxCubit {}

class _MockBitboxWallet extends Mock implements BitboxWallet {}

void main() {
  late _MockConnectBitboxCubit cubit;
  late _MockBitboxWallet wallet;

  setUp(() {
    cubit = _MockConnectBitboxCubit();
    wallet = _MockBitboxWallet();
  });

  Future<void> pumpView(WidgetTester tester, BitboxConnectionState state) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, const Stream<BitboxConnectionState>.empty(), initialState: state);
    await tester.pumpApp(
      BlocProvider<ConnectBitboxCubit>.value(
        value: cubit,
        child: ConnectBitboxView(onFinish: (_) {}),
      ),
    );
  }

  group('$ConnectBitboxView', () {
    testWidgets('BitboxCapturingSignature shows a spinner and no buttons', (tester) async {
      await pumpView(tester, BitboxCapturingSignature(wallet));

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.byType(AppFilledButton), findsNothing);
    });

    testWidgets('BitboxSignatureFailed shows retry and continue buttons', (tester) async {
      await pumpView(tester, BitboxSignatureFailed(wallet));

      expect(find.byType(AppFilledButton), findsNWidgets(2));
    });

    testWidgets('BitboxSignatureFailed retry button calls retrySignatureCapture',
        (tester) async {
      when(() => cubit.retrySignatureCapture()).thenAnswer((_) async {});
      await pumpView(tester, BitboxSignatureFailed(wallet));

      final buttons = tester.widgetList<AppFilledButton>(find.byType(AppFilledButton)).toList();
      buttons[0].onPressed?.call();
      verify(() => cubit.retrySignatureCapture()).called(1);
    });

    testWidgets('BitboxSignatureFailed continue button calls continueWithoutSignature',
        (tester) async {
      when(() => cubit.continueWithoutSignature()).thenReturn(null);
      await pumpView(tester, BitboxSignatureFailed(wallet));

      final buttons = tester.widgetList<AppFilledButton>(find.byType(AppFilledButton)).toList();
      buttons[1].onPressed?.call();
      verify(() => cubit.continueWithoutSignature()).called(1);
    });

    testWidgets('ConnectContent honors confirmLabel and cancelLabel overrides', (tester) async {
      await tester.pumpApp(
        ConnectContent(
          imagePath: 'assets/images/bitbox/test.svg',
          title: 'Title',
          onConfirm: () {},
          onCancel: () {},
          confirmLabel: 'Retry now',
          cancelLabel: 'Skip',
          child: const SizedBox.shrink(),
        ),
      );

      final buttons = tester.widgetList<AppFilledButton>(find.byType(AppFilledButton)).toList();
      expect(buttons[0].label, 'Retry now');
      expect(buttons[1].label, 'Skip');
    });
  });
}
