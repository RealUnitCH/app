import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'legal_disclaimer_state.dart';

class LegalDisclaimerCubit extends Cubit<LegalDisclaimerState> {
  LegalDisclaimerCubit() : super(const LegalDisclaimerState());

  void nextStep({VoidCallback? onComplete}) {
    if (!state.isLastStep) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    } else {
      onComplete?.call();
    }
  }

  void previousStep() {
    if (state.canGoBack) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }
}
