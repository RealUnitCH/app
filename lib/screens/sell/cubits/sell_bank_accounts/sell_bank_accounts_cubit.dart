import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/bank_account.dart';

class SellBankAccountsCubit extends Cubit<List<BankAccount>> {
  SellBankAccountsCubit() : super([]);

  void addBankAccount({required BankAccount bankAccount}) {
    final updatedList = List<BankAccount>.from(state)..add(bankAccount);
    emit(updatedList);
  }
}
