import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

class ExpiryState {
  final int secondsRemaining;

  ExpiryState(this.secondsRemaining);

  bool get isExpired => secondsRemaining <= 0;
}

class ExpiryCubit extends Cubit<ExpiryState> {
  ExpiryCubit(this.expiryDate)
      : super(ExpiryState(expiryDate.difference(DateTime.now()).inSeconds)) {
    _expiryTimer = Timer.periodic(const Duration(milliseconds: 500), _calculateTimeLeft);
  }

  DateTime expiryDate;
  Timer? _expiryTimer;

  @override
  Future<void> close() {
    _expiryTimer?.cancel();
    return super.close();
  }

  void _calculateTimeLeft(Timer timer) {
    final newState = ExpiryState(expiryDate.difference(DateTime.now()).inSeconds);
    emit(newState);
    if (newState.isExpired) timer.cancel();
  }
}
