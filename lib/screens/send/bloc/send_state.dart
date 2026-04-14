part of 'send_bloc.dart';

enum SendStatus { initial, inProgress, success, failure }

class SendState extends Equatable {
  const SendState({
    this.status = SendStatus.initial,
    this.asset = dEUROAsset,
    this.receiver = '',
    this.amount = '0',
    this.isValid = false,
    this.balances = const [],
  });

  final SendStatus status;
  final Asset asset;
  final String receiver;
  final String amount;
  final bool isValid;
  final List<Balance> balances;

  Blockchain get blockchain => Blockchain.getFromChainId(asset.chainId);

  SendState copyWith({
    SendStatus? status,
    String? receiver,
    String? amount,
    bool? isValid,
    Asset? asset,
    List<Balance>? balances,
  }) =>
      SendState(
        status: status ?? this.status,
        receiver: receiver ?? this.receiver,
        amount: amount ?? this.amount,
        isValid: isValid ?? this.isValid,
        asset: asset ?? this.asset,
        balances: balances ?? this.balances,
      );

  @override
  List<Object?> get props => [status, receiver, amount, asset, balances];
}
