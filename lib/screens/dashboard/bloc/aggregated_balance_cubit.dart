import 'package:realunit_wallet/models/balance.dart';
import 'package:realunit_wallet/packages/repository/balance_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AggregatedBalance {
  final List<Balance> balances;

  BigInt get balance {
    BigInt aggregate = BigInt.zero;
    for (final bla in balances) {
      aggregate += bla.balance;
    }
    return aggregate;
  }

  const AggregatedBalance({required this.balances});
}

class AggregatedBalanceCubit extends Cubit<AggregatedBalance> {
  AggregatedBalanceCubit(this._repository, this._balances)
      : super(AggregatedBalance(balances: _balances)) {
    for (final balance in _balances) {
      _repository.watchBalance(balance).listen(_updateBalances);
    }
  }

  final List<Balance> _balances;
  final BalanceRepository _repository;

  void _updateBalances(Balance balance) {
    _balances.firstWhere((row) => row == balance).balance = balance.balance;
    emit(AggregatedBalance(balances: _balances));
  }
}
