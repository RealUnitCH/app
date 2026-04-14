part of 'send_bloc.dart';

sealed class SendEvent extends Equatable {
  const SendEvent();

  @override
  List<Object> get props => [];
}

final class AmountChangedAdd extends SendEvent {
  const AmountChangedAdd(this.amount);

  final int amount;

  @override
  List<Object> get props => [amount];
}

final class AmountChangedDecimal extends SendEvent {
  const AmountChangedDecimal();
}

final class AmountChangedDelete extends SendEvent {
  const AmountChangedDelete();
}

final class ReceiverChanged extends SendEvent {
  const ReceiverChanged(this.receiver);

  final String receiver;

  @override
  List<Object> get props => [receiver];
}

final class PasteReceiver extends SendEvent {
  const PasteReceiver();
}

final class AssetChanged extends SendEvent {
  const AssetChanged(this.asset);

  final Asset asset;

  @override
  List<Object> get props => [asset];
}

final class SendSubmitted extends SendEvent {
  const SendSubmitted();
}

final class LoadBalances extends SendEvent {
  const LoadBalances();
}
