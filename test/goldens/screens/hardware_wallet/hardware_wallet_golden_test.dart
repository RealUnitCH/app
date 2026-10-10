import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/hardware_wallet/cubit/move_balance_cubit.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_buy_page.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_intro_page.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_paired_page.dart';
import 'package:realunit_wallet/screens/hardware_wallet/hardware_wallet_setup_page.dart';
import 'package:realunit_wallet/screens/hardware_wallet/move_balance_page.dart';
import 'package:realunit_wallet/setup/routing/routes/app_routes.dart';
import 'package:realunit_wallet/styles/themes.dart';

import '../../../helper/helper.dart';

class _MockMoveBalanceCubit extends MockCubit<MoveBalanceState>
    implements MoveBalanceCubit {}

void main() {
  group('$HardwareWalletIntroPage', () {
    goldenTest(
      'intro copy and move CTA',
      fileName: 'hardware_wallet_intro_page',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const HardwareWalletIntroPage()),
    );
  });

  group('$HardwareWalletBuyPage', () {
    goldenTest(
      'shop links and suitable-device confirm',
      fileName: 'hardware_wallet_buy_page',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const HardwareWalletBuyPage()),
    );
  });

  group('$HardwareWalletSetupPage', () {
    goldenTest(
      'set-up-in-BitBox-app copy',
      fileName: 'hardware_wallet_setup_page',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const HardwareWalletSetupPage()),
    );
  });

  group('$HardwareWalletPairedPage', () {
    goldenTest(
      'register and continue after pairing',
      fileName: 'hardware_wallet_paired_page',
      constraints: phoneConstraints,
      builder: () => wrapForGolden(const HardwareWalletPairedPage()),
    );
  });

  group('$MoveBalanceView', () {
    late _MockMoveBalanceCubit cubit;

    setUp(() {
      cubit = _MockMoveBalanceCubit();
    });

    goldenTest(
      'both directions with whole-share balances',
      fileName: 'move_balance_page',
      constraints: phoneConstraints,
      builder: () {
        const state = MoveBalanceInitial(softwareBalance: 10, bitboxBalance: 4);
        when(() => cubit.state).thenReturn(state);
        whenListen(
          cubit,
          const Stream<MoveBalanceState>.empty(),
          initialState: state,
        );
        return wrapForGolden(
          BlocProvider<MoveBalanceCubit>.value(
            value: cubit,
            child: const MoveBalanceView(),
          ),
        );
      },
    );

    goldenTest(
      'failure shows the API message',
      fileName: 'move_balance_page_failure',
      constraints: phoneConstraints,
      builder: () {
        const state = MoveBalanceFailure('Recipient is not a registered shareholder');
        when(() => cubit.state).thenReturn(state);
        whenListen(
          cubit,
          const Stream<MoveBalanceState>.empty(),
          initialState: state,
        );
        return wrapForGolden(
          BlocProvider<MoveBalanceCubit>.value(
            value: cubit,
            child: const MoveBalanceView(),
          ),
        );
      },
    );

    Widget wrapView(MoveBalanceState state) {
      when(() => cubit.state).thenReturn(state);
      whenListen(
        cubit,
        const Stream<MoveBalanceState>.empty(),
        initialState: state,
      );
      return wrapForGolden(
        BlocProvider<MoveBalanceCubit>.value(
          value: cubit,
          child: const MoveBalanceView(),
        ),
      );
    }

    goldenTest(
      'quote ready with REALU fee',
      fileName: 'move_balance_quote_fee',
      constraints: phoneConstraints,
      builder: () => wrapView(
        const MoveBalanceQuoteReady(
          direction: MoveBalanceDirection.softwareToBitbox,
          amount: 9,
          networkFeeRealu: 1,
          ethPaysGas: false,
          softwareBalance: 10,
          bitboxBalance: 4,
        ),
      ),
    );

    goldenTest(
      'quote ready with ETH gas',
      fileName: 'move_balance_quote_eth',
      constraints: phoneConstraints,
      builder: () => wrapView(
        const MoveBalanceQuoteReady(
          direction: MoveBalanceDirection.softwareToBitbox,
          amount: 9,
          networkFeeRealu: 1,
          ethPaysGas: true,
          softwareBalance: 10,
          bitboxBalance: 4,
        ),
      ),
    );

    goldenTest(
      'need ETH for gas',
      fileName: 'move_balance_need_eth',
      constraints: phoneConstraints,
      builder: () => wrapView(
        const MoveBalanceNeedEth('Insufficient ETH for gas: need 0.01, have 0'),
      ),
    );

    goldenTest(
      'failure with retry and register',
      fileName: 'move_balance_failure_retry',
      constraints: phoneConstraints,
      builder: () => wrapView(
        const MoveBalanceFailure('Broadcast failed', canRetry: true),
      ),
    );

    goldenTest(
      'software retry without register',
      fileName: 'move_balance_failure_retry_software',
      constraints: phoneConstraints,
      builder: () => wrapView(
        const MoveBalanceFailure(
          'Broadcast failed',
          canRetry: true,
          direction: MoveBalanceDirection.softwareToBitbox,
        ),
      ),
    );

    goldenTest(
      'wallets missing',
      fileName: 'move_balance_wallets_missing',
      constraints: phoneConstraints,
      builder: () => wrapView(
        const MoveBalanceFailure(
          '',
          reason: MoveBalanceFailureReason.walletsMissing,
        ),
      ),
    );

    goldenTest(
      'software empty',
      fileName: 'move_balance_software_empty',
      constraints: phoneConstraints,
      builder: () => wrapView(
        const MoveBalanceFailure(
          '',
          reason: MoveBalanceFailureReason.softwareEmpty,
        ),
      ),
    );

    goldenTest(
      'bitbox empty',
      fileName: 'move_balance_bitbox_empty',
      constraints: phoneConstraints,
      builder: () => wrapView(
        const MoveBalanceFailure(
          '',
          reason: MoveBalanceFailureReason.bitboxEmpty,
        ),
      ),
    );

    goldenTest(
      'fee exceeds balance',
      fileName: 'move_balance_fee_exceeds',
      constraints: phoneConstraints,
      builder: () => wrapView(
        const MoveBalanceFailure(
          '',
          reason: MoveBalanceFailureReason.feeExceedsBalance,
        ),
      ),
    );

    goldenTest(
      'no quote',
      fileName: 'move_balance_no_quote',
      constraints: phoneConstraints,
      builder: () => wrapView(
        const MoveBalanceFailure(
          '',
          reason: MoveBalanceFailureReason.noQuote,
        ),
      ),
    );

    goldenTest(
      'quote mismatch',
      fileName: 'move_balance_quote_mismatch',
      constraints: phoneConstraints,
      builder: () => wrapView(
        const MoveBalanceFailure(
          '',
          reason: MoveBalanceFailureReason.quoteMismatch,
        ),
      ),
    );

    goldenTest(
      'success',
      fileName: 'move_balance_success',
      constraints: phoneConstraints,
      builder: () => wrapView(
        const MoveBalanceSuccess(MoveBalanceDirection.softwareToBitbox),
      ),
    );

    goldenTest(
      'registration required stays visible',
      fileName: 'move_balance_registration_required',
      constraints: phoneConstraints,
      builder: () {
        const state = MoveBalanceRegistrationRequired('register');
        when(() => cubit.state).thenReturn(state);
        whenListen(
          cubit,
          const Stream<MoveBalanceState>.empty(),
          initialState: state,
        );
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => BlocProvider<MoveBalanceCubit>.value(
                value: cubit,
                child: const MoveBalanceView(),
              ),
            ),
            GoRoute(
              name: AppRoutes.kyc,
              path: '/kyc',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        );
        return MaterialApp.router(
          theme: realUnitTheme,
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );

    goldenTest(
      'loading shows only the activity indicator',
      fileName: 'move_balance_loading',
      constraints: phoneConstraints,
      // The indicator never settles, so pumpAndSettle times out.
      pumpBeforeTest: pumpOnce,
      builder: () => wrapView(const MoveBalanceLoading()),
    );

    goldenTest(
      'confirming shows only the activity indicator',
      fileName: 'move_balance_confirming',
      constraints: phoneConstraints,
      pumpBeforeTest: pumpOnce,
      builder: () => wrapView(const MoveBalanceConfirming()),
    );
  });
}
