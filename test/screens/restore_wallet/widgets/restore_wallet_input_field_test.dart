import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/restore_wallet/restore_wallet_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/cubit/validate_seed/validate_seed_cubit.dart';
import 'package:realunit_wallet/screens/restore_wallet/widgets/restore_wallet_input_field.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/mnemonic_field.dart';

import '../../../helper/helper.dart';

class _MockValidateSeedCubit extends MockCubit<ValidateSeedState>
    implements ValidateSeedCubit {}

class _MockRestoreWalletCubit extends MockCubit<RestoreWalletState>
    implements RestoreWalletCubit {}

class _Host extends StatefulWidget {
  const _Host({required this.validate, required this.restore});

  final ValidateSeedCubit validate;
  final RestoreWalletCubit restore;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late final List<MnemonicInputFieldController> controllers;
  late final List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(12, (_) => MnemonicInputFieldController());
    focusNodes = List.generate(12, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ValidateSeedCubit>.value(value: widget.validate),
        BlocProvider<RestoreWalletCubit>.value(value: widget.restore),
      ],
      child: Material(
        child: RestoreWalletInputField(
          controllers: controllers,
          focusNodes: focusNodes,
        ),
      ),
    );
  }
}

void main() {
  late _MockValidateSeedCubit validate;
  late _MockRestoreWalletCubit restore;

  setUp(() {
    validate = _MockValidateSeedCubit();
    restore = _MockRestoreWalletCubit();
  });

  Color borderColor(WidgetTester tester) {
    final field = tester.widget<MnemonicInputField>(find.byType(MnemonicInputField));
    return field.borderColor;
  }

  group('$RestoreWalletInputField borderColor', () {
    testWidgets('valid + idle → green', (tester) async {
      when(() => validate.state).thenReturn(ValidateSeedState.valid);
      when(() => restore.state).thenReturn(const RestoreWalletState());

      await tester.pumpApp(_Host(validate: validate, restore: restore));

      expect(borderColor(tester), RealUnitColors.green);
    });

    testWidgets('valid + loading → okker', (tester) async {
      when(() => validate.state).thenReturn(ValidateSeedState.valid);
      when(() => restore.state).thenReturn(const RestoreWalletState(isLoading: true));

      await tester.pumpApp(_Host(validate: validate, restore: restore));

      expect(borderColor(tester), RealUnitColors.okker);
    });

    testWidgets('invalid → status red', (tester) async {
      when(() => validate.state).thenReturn(ValidateSeedState.invalid);
      when(() => restore.state).thenReturn(const RestoreWalletState());

      await tester.pumpApp(_Host(validate: validate, restore: restore));

      expect(borderColor(tester), RealUnitColors.status.red600);
    });

    testWidgets('uncomplete (default) → okker', (tester) async {
      when(() => validate.state).thenReturn(ValidateSeedState.uncomplete);
      when(() => restore.state).thenReturn(const RestoreWalletState());

      await tester.pumpApp(_Host(validate: validate, restore: restore));

      expect(borderColor(tester), RealUnitColors.okker);
    });
  });
}
