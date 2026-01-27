import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';

part 'registration_step_state.dart';

class RegistrationStepCubit extends Cubit<RegistrationStepState> {
  RegistrationStepCubit()
      : super(
          const RegistrationStepState(
            step: RegistrationStep.email,
            steps: [
              RegistrationStep.email,
              RegistrationStep.personal,
              RegistrationStep.address,
              RegistrationStep.completed,
            ],
          ),
        );

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
    final steps = List<RegistrationStep>.from(state.steps);
    final hasVerification = state.steps.contains(RegistrationStep.emailVerification);

    if (required && !hasVerification) {
      final insertIndex = state.steps.indexOf(RegistrationStep.email) + 1;
      steps.insert(insertIndex, RegistrationStep.emailVerification);
    }

    if (!required && hasVerification) {
      steps.remove(RegistrationStep.emailVerification);
    }

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
