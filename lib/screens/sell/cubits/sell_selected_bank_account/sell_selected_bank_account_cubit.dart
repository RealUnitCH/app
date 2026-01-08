import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/bank_account.dart';

class SellSelectedBankAccountCubit extends Cubit<BankAccount?> {
  SellSelectedBankAccountCubit() : super(null);

  void selectBankAccount(BankAccount? account) {
    emit(account);
  }
}
