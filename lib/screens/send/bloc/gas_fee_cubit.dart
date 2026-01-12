import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/models/blockchain.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/utils/format_fixed.dart';

class GasFeeState {
  final BigInt gasFee;

  GasFeeState(this.gasFee);

  String get formatedFee => gasFee < BigInt.parse('1000000000000')
      ? '< 0.000001'
      : formatFixed(gasFee, 18, fractionalDigits: 6);
}

class GasFeeCubit extends Cubit<GasFeeState> {
  GasFeeCubit(this._appStore, [this.blockchain = Blockchain.ethereum])
      : super(GasFeeState(BigInt.zero)) {
    _feeTimer = Timer.periodic(const Duration(milliseconds: 600), _feeSync);
  }

  final AppStore _appStore;
  Blockchain blockchain;
  Timer? _feeTimer;

  @override
  Future<void> close() {
    _feeTimer?.cancel();
    return super.close();
  }

  Future<void> _feeSync(Timer timer) async {
    final priorityFee = 0;
    final client = _appStore.getClient(blockchain.chainId);
    try {
      final gasPrice = await client.getGasPrice();
      final estimatedGas = await client.estimateGas();
      final fee = (gasPrice.getInWei + BigInt.from(priorityFee)) * estimatedGas;
      if (fee != state.gasFee) emit(GasFeeState(fee));
    } on StateError catch (_) {}
  }
}
