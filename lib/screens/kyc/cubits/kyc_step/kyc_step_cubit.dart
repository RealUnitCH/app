import 'package:flutter_bloc/flutter_bloc.dart';

part 'kyc_step_state.dart';

class KycStepCubit extends Cubit<KycStepState> {
  KycStepCubit() : super(const KycStepState(KycStep.personal));

  void next() {
    int currentIndex = state.index;
    if (currentIndex >= 0 && currentIndex < _stepsOrder.length - 1) {
      emit(KycStepState(_stepsOrder.elementAt(currentIndex + 1)));
    }
  }

  void previous() {
    int currentIndex = state.index;
    if (currentIndex > 0 && currentIndex <= _stepsOrder.length - 1) {
      emit(KycStepState(_stepsOrder.elementAt(currentIndex - 1)));
    }
  }

  final List<KycStep> _stepsOrder = [
    KycStep.personal,
    KycStep.address,
    KycStep.completed,
  ];
}
