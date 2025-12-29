import 'package:flutter_bloc/flutter_bloc.dart';

part 'registration_step_state.dart';

class RegistrationStepCubit extends Cubit<RegistrationStepState> {
  RegistrationStepCubit() : super(const RegistrationStepState(RegistrationStep.personal));

  void next() {
    int currentIndex = state.index;
    if (currentIndex >= 0 && currentIndex < _stepsOrder.length - 1) {
      emit(RegistrationStepState(_stepsOrder.elementAt(currentIndex + 1)));
    }
  }

  void previous() {
    int currentIndex = state.index;
    if (currentIndex > 0 && currentIndex <= _stepsOrder.length - 1) {
      emit(RegistrationStepState(_stepsOrder.elementAt(currentIndex - 1)));
    }
  }
}
