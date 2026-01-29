import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';

part 'registration_step_state.dart';

class RegistrationStepCubit extends Cubit<RegistrationStepState> {
  RegistrationStepCubit()
      : super(
          RegistrationStepState(
            step: RegistrationStep.email,
            steps: _steps(emailVerificationRequired: false),
          ),
        );

  static List<RegistrationStep> _steps({
    required bool emailVerificationRequired,
  }) {
    return [
      RegistrationStep.email,
      if (emailVerificationRequired) RegistrationStep.emailVerification,
      RegistrationStep.personal,
      RegistrationStep.address,
      RegistrationStep.completed,
    ];
  }

  void next() {
    final currentIndex = state.index;
    if (currentIndex >= 0 && currentIndex < state.steps.length - 1) {
      emit(
        RegistrationStepState(
          step: state.steps.elementAt(currentIndex + 1),
          steps: state.steps,
        ),
      );
    }
  }

  void previous() {
    final currentIndex = state.index;
    if (currentIndex > 0 && currentIndex <= state.steps.length - 1) {
      emit(
        RegistrationStepState(
          step: state.steps.elementAt(currentIndex - 1),
          steps: state.steps,
        ),
      );
    }
  }

  void syncEmailVerification({required bool required}) {
    final steps = _steps(emailVerificationRequired: required);

    if (!listEquals(steps, state.steps)) {
      emit(
        RegistrationStepState(
          step: state.step,
          steps: steps,
        ),
      );
    }
  }
}
