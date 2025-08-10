part of 'savings_bloc.dart';

sealed class SavingsEvent extends Equatable {
  const SavingsEvent();

  @override
  List<Object> get props => [];
}

class EnableSavings extends SavingsEvent {
  const EnableSavings();
}

class LoadIsEnabled extends SavingsEvent {
  const LoadIsEnabled();
}

final class LoadSavingsBalance extends SavingsEvent {
  const LoadSavingsBalance();
}

final class LoadFromCache extends SavingsEvent {
  const LoadFromCache();
}

final class CollectInterest extends SavingsEvent {
  const CollectInterest();
}

final class CompoundInterest extends SavingsEvent {
  const CompoundInterest();
}
