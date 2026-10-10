import 'dart:typed_data';

import 'package:convert/convert.dart' as convert;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/hardware_wallet/bitbox_credentials.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';
import 'package:realunit_wallet/packages/service/balance_service.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_faucet_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_address_unavailable_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/bitbox_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/buy_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/transfer_exceptions.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/broadcast_transaction_request_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/transfer/dto/real_unit_hardware_transfer_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/transfer/dto/real_unit_transfer_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/transfer/dto/real_unit_transfer_payment_info_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_hardware_transfer_service.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_transfer_service.dart';
import 'package:realunit_wallet/packages/service/wallet_service.dart';
import 'package:realunit_wallet/packages/wallet/wallet.dart';
import 'package:realunit_wallet/screens/home/bloc/home_bloc.dart';

part 'move_balance_state.dart';

class MoveBalanceCubit extends Cubit<MoveBalanceState> {
  final WalletService _walletService;
  final RealUnitTransferService _transferService;
  final RealUnitHardwareTransferService _hardwareTransferService;
  final DfxFaucetService _faucetService;
  final AppStore _appStore;
  final HomeBloc _homeBloc;
  final BalanceService _balanceService;

  AWallet? _software;
  AWallet? _bitbox;
  int _softwareBalance = 0;
  int _bitboxBalance = 0;

  RealUnitTransferPaymentInfoDto? _softwareQuote;
  RealUnitHardwareTransferPaymentInfoDto? _hardwareQuote;
  BroadcastTransactionRequestDto? _signedHardwareTx;
  MoveBalanceDirection? _direction;
  bool _prepareInFlight = false;

  bool _confirmInFlight = false;
  bool _confirmSent = false;
  bool _faucetRequested = false;

  MoveBalanceCubit({
    required WalletService walletService,
    required RealUnitTransferService transferService,
    required RealUnitHardwareTransferService hardwareTransferService,
    required DfxFaucetService faucetService,
    required AppStore appStore,
    required HomeBloc homeBloc,
    required BalanceService balanceService,
  }) : _walletService = walletService,
       _transferService = transferService,
       _hardwareTransferService = hardwareTransferService,
       _faucetService = faucetService,
       _appStore = appStore,
       _homeBloc = homeBloc,
       _balanceService = balanceService,
       super(const MoveBalanceLoading());

  Future<void> load() async {
    emit(const MoveBalanceLoading());
    try {
      final wallets = await _walletService.listWallets();
      for (final wallet in wallets) {
        if (wallet.walletType == WalletType.software) {
          _software = wallet;
        } else if (wallet.walletType == WalletType.bitbox) {
          _bitbox = wallet;
        }
      }
      final software = _software;
      final bitbox = _bitbox;
      if (software == null || bitbox == null) {
        emit(
          const MoveBalanceFailure(
            '',
            reason: MoveBalanceFailureReason.walletsMissing,
          ),
        );
        return;
      }
      _softwareBalance = await _freshShares(software);
      _bitboxBalance = await _freshShares(bitbox);
      if (isClosed) {
        return;
      }
      emit(
        MoveBalanceInitial(
          softwareBalance: _softwareBalance,
          bitboxBalance: _bitboxBalance,
        ),
      );
    } catch (e) {
      if (isClosed) {
        return;
      }
      emit(MoveBalanceFailure(ApiException.userFacingMessage(e)));
    }
  }

  Future<void> prepareSoftwareToBitbox() async {
    if (_blocksOtherPrepare()) {
      return;
    }
    final software = _software;
    final bitbox = _bitbox;
    if (software == null || bitbox == null) {
      emit(
        const MoveBalanceFailure(
          '',
          reason: MoveBalanceFailureReason.walletsMissing,
        ),
      );
      return;
    }
    _prepareInFlight = true;
    emit(const MoveBalanceLoading());
    try {
      await _switchTo(software.id);
      _softwareBalance = await _freshShares(software);
      if (_softwareBalance < 1) {
        _emitLocalFailure(MoveBalanceFailureReason.softwareEmpty);
        return;
      }
      final probe = await _transferService.prepareTransfer(
        RealUnitTransferDto(
          toAddress: _addressOf(bitbox),
          amount: 1,
        ),
      );
      if (probe.amount != 1) {
        _emitLocalFailure(MoveBalanceFailureReason.quoteMismatch);
        return;
      }
      if (1 + probe.networkFeeRealu > _softwareBalance) {
        _emitLocalFailure(MoveBalanceFailureReason.feeExceedsBalance);
        return;
      }
      final target = _softwareBalance - probe.networkFeeRealu;
      if (target == 1) {
        _acceptSoftwareQuote(probe);
        return;
      }
      final quote = await _transferService.prepareTransfer(
        RealUnitTransferDto(
          toAddress: _addressOf(bitbox),
          amount: target,
        ),
      );
      if (quote.amount != target) {
        _emitLocalFailure(MoveBalanceFailureReason.quoteMismatch);
        return;
      }
      if (quote.amount + quote.networkFeeRealu > _softwareBalance) {
        _emitLocalFailure(MoveBalanceFailureReason.feeExceedsBalance);
        return;
      }
      _acceptSoftwareQuote(quote);
    } on RegistrationRequiredException catch (e) {
      _emitUnlessClosed(MoveBalanceRegistrationRequired(e.message));
    } on ApiException catch (e) {
      _emitUnlessClosed(MoveBalanceFailure(e.message));
    } catch (e) {
      _emitUnlessClosed(MoveBalanceFailure(ApiException.userFacingMessage(e)));
    } finally {
      _prepareInFlight = false;
    }
  }

  Future<void> prepareBitboxToSoftware() async {
    if (_blocksOtherPrepare()) {
      return;
    }
    final software = _software;
    final bitbox = _bitbox;
    if (software == null || bitbox == null) {
      emit(
        const MoveBalanceFailure(
          '',
          reason: MoveBalanceFailureReason.walletsMissing,
        ),
      );
      return;
    }
    _prepareInFlight = true;
    try {
      // The load() cache is not the decision. A later credit must still move,
      // and a still-empty BitBox must not drop a software quote.
      _bitboxBalance = await _freshShares(bitbox);
      if (isClosed) {
        return;
      }
      if (_bitboxBalance < 1) {
        if (_softwareQuote != null) {
          return;
        }
        _emitLocalFailure(MoveBalanceFailureReason.bitboxEmpty);
        return;
      }
      // A failed prepare must not leave a software quote that Retry would confirm.
      _dropPendingMove();
      emit(const MoveBalanceLoading());
      await _switchTo(bitbox.id);
      final credentials = _appStore.wallet.currentAccount.primaryAddress;
      if (credentials is! BitboxCredentials || !credentials.isConnected) {
        emit(const MoveBalanceDisconnected());
        return;
      }
      final quote = await _hardwareTransferService.prepareTransfer(
        RealUnitHardwareTransferRequestDto(
          toAddress: _addressOf(software),
          amount: _bitboxBalance,
        ),
      );
      if (isClosed) {
        return;
      }
      if (quote.amount != _bitboxBalance ||
          quote.toAddress.toLowerCase() != _addressOf(software).toLowerCase()) {
        _emitLocalFailure(MoveBalanceFailureReason.quoteMismatch);
        return;
      }
      _direction = MoveBalanceDirection.bitboxToSoftware;
      _hardwareQuote = quote;
      _softwareQuote = null;
      _signedHardwareTx = null;
      _confirmSent = false;
      emit(
        MoveBalanceQuoteReady(
          direction: MoveBalanceDirection.bitboxToSoftware,
          amount: quote.amount,
          networkFeeRealu: 0,
          ethPaysGas: true,
          softwareBalance: _softwareBalance,
          bitboxBalance: _bitboxBalance,
        ),
      );
    } on BitboxNotConnectedException {
      _emitUnlessClosed(const MoveBalanceDisconnected());
    } on RegistrationRequiredException catch (e) {
      _emitUnlessClosed(MoveBalanceRegistrationRequired(e.message));
    } on InsufficientEthForGasException catch (e) {
      await _handleInsufficientEth(e);
    } on ApiException catch (e) {
      _emitUnlessClosed(MoveBalanceFailure(e.message));
    } catch (e) {
      _emitUnlessClosed(MoveBalanceFailure(ApiException.userFacingMessage(e)));
    } finally {
      _prepareInFlight = false;
    }
  }

  /// The device dropped. Pairing again must reuse this row: a new view wallet
  /// would sit beside it and [WalletService.createBitboxWallet] would make
  /// that new row current.
  Future<BitboxWallet> reattachBitbox() async {
    final bitbox = _bitbox;
    if (bitbox is! BitboxWallet) {
      throw StateError('No paired BitBox');
    }
    try {
      final existing = await _walletService.existingBitboxWallet();
      if (existing.id != bitbox.id) {
        throw StateError('No paired BitBox');
      }
      return existing;
    } on BitboxAddressMismatchException {
      throw StateError('No paired BitBox');
    }
  }

  Future<void> confirm() async {
    if (_confirmInFlight) {
      return;
    }
    if (_prepareInFlight) {
      return;
    }
    if (state is MoveBalanceSuccess) {
      return;
    }
    final direction = _direction;
    if (direction == MoveBalanceDirection.softwareToBitbox) {
      await _confirmSoftwareToBitbox();
      return;
    }
    if (direction == MoveBalanceDirection.bitboxToSoftware) {
      await _confirmBitboxToSoftware();
    }
  }

  Future<void> retryAfterConnection() async {
    if (_hardwareQuote != null || _signedHardwareTx != null) {
      await confirm();
      return;
    }
    await prepareBitboxToSoftware();
  }

  Future<void> retryPrepareBitboxToSoftware() => prepareBitboxToSoftware();

  /// After KYC returns, drop the pending move and show both directions again.
  Future<void> continueAfterRegistration() async {
    _dropPendingMove();
    _confirmSent = false;
    _prepareInFlight = false;
    _confirmInFlight = false;
    await load();
  }

  Future<void> _confirmSoftwareToBitbox() async {
    final quote = _softwareQuote;
    final bitbox = _bitbox;
    final software = _software;
    if (quote == null || bitbox == null || software == null) {
      // coverage:ignore-start
      // Direction is assigned only together with the quote, after both
      // wallets are loaded. Kept so a broken assignment reports noQuote.
      emit(
        const MoveBalanceFailure(
          '',
          reason: MoveBalanceFailureReason.noQuote,
        ),
      );
      return;
      // coverage:ignore-end
    }
    _confirmInFlight = true;
    try {
      emit(const MoveBalanceConfirming());
      await _switchTo(software.id);
      _confirmSent = true;
      await _transferService.confirmTransfer(
        quote,
        confirmedRecipient: _addressOf(bitbox),
        confirmedAmount: quote.amount,
      );
      _restartBalanceSync();
      _emitUnlessClosed(
        const MoveBalanceSuccess(MoveBalanceDirection.softwareToBitbox),
      );
    } on TransferAlreadyConfirmedException {
      _restartBalanceSync();
      _emitUnlessClosed(
        const MoveBalanceSuccess(MoveBalanceDirection.softwareToBitbox),
      );
    } on TransferReceiptTimeoutException {
      _restartBalanceSync();
      _emitUnlessClosed(
        const MoveBalanceSuccess(MoveBalanceDirection.softwareToBitbox),
      );
    } on RegistrationRequiredException catch (e) {
      _emitUnlessClosed(MoveBalanceRegistrationRequired(e.message));
    } on ApiException catch (e) {
      _emitUnlessClosed(
        MoveBalanceFailure(
          e.message,
          canRetry: true,
          direction: MoveBalanceDirection.softwareToBitbox,
        ),
      );
    } catch (e) {
      _emitUnlessClosed(
        MoveBalanceFailure(
          ApiException.userFacingMessage(e),
          canRetry: true,
          direction: MoveBalanceDirection.softwareToBitbox,
        ),
      );
    } finally {
      _confirmInFlight = false;
    }
  }

  Future<void> _confirmBitboxToSoftware() async {
    final quote = _hardwareQuote;
    if (quote == null) {
      // coverage:ignore-start
      // The BitBox direction is assigned only together with this quote.
      emit(
        const MoveBalanceFailure(
          '',
          reason: MoveBalanceFailureReason.noQuote,
        ),
      );
      return;
      // coverage:ignore-end
    }
    _confirmInFlight = true;
    try {
      emit(const MoveBalanceConfirming());
      var signed = _signedHardwareTx;
      if (signed == null) {
        final credentials = _appStore.wallet.currentAccount.primaryAddress;
        if (credentials is! BitboxCredentials || !credentials.isConnected) {
          emit(const MoveBalanceDisconnected());
          return;
        }
        signed = await _signTransaction(quote.unsignedTx, credentials);
        _signedHardwareTx = signed;
      }
      _confirmSent = true;
      await _hardwareTransferService.broadcastTransfer(signed);
      _restartBalanceSync();
      _emitUnlessClosed(
        const MoveBalanceSuccess(MoveBalanceDirection.bitboxToSoftware),
      );
    } on BitboxNotConnectedException {
      _emitUnlessClosed(const MoveBalanceDisconnected());
    } on RegistrationRequiredException catch (e) {
      _emitUnlessClosed(MoveBalanceRegistrationRequired(e.message));
    } on ApiException catch (e) {
      _confirmSent = true;
      _emitUnlessClosed(MoveBalanceFailure(e.message, canRetry: true));
    } catch (e) {
      _emitUnlessClosed(
        MoveBalanceFailure(ApiException.userFacingMessage(e), canRetry: true),
      );
    } finally {
      _confirmInFlight = false;
    }
  }

  bool _blocksOtherPrepare() =>
      _prepareInFlight ||
      _confirmInFlight ||
      (_confirmSent && (_softwareQuote != null || _hardwareQuote != null));

  void _dropPendingMove() {
    _direction = null;
    _softwareQuote = null;
    _hardwareQuote = null;
    _signedHardwareTx = null;
  }

  Future<void> _handleInsufficientEth(InsufficientEthForGasException error) async {
    if (_faucetRequested) {
      _emitUnlessClosed(MoveBalanceNeedEth(error.message));
      return;
    }
    try {
      await _faucetService.requestFaucet();
      _faucetRequested = true;
      _emitUnlessClosed(MoveBalanceNeedEth(error.message));
    } catch (e) {
      _emitUnlessClosed(MoveBalanceNeedEth(ApiException.userFacingMessage(e)));
    }
  }

  Future<void> _switchTo(int id) async {
    final wallet = await _walletService.switchCurrentWallet(id);
    _appStore.wallet = wallet;
    _homeBloc.add(LoadWalletEvent(wallet));
  }

  void _restartBalanceSync() {
    final software = _software;
    final bitbox = _bitbox;
    if (software != null) {
      _balanceService.updateBalance(_addressOf(software));
    }
    if (bitbox != null) {
      _balanceService.updateBalance(_addressOf(bitbox));
    }
    _balanceService.startSync(_appStore.primaryAddress);
  }

  Future<int> _freshShares(AWallet wallet) =>
      _balanceService.freshShareBalance(_addressOf(wallet));

  String _addressOf(AWallet wallet) => wallet.currentAccount.primaryAddress.address.hex;

  Future<BroadcastTransactionRequestDto> _signTransaction(
    String rawTransaction,
    BitboxCredentials credentials,
  ) async {
    final payload = Uint8List.fromList(
      convert.hex.decode(
        rawTransaction.startsWith('0x') ? rawTransaction.substring(2) : rawTransaction,
      ),
    );
    final sig = await credentials.signToSignature(
      payload,
      chainId: _appStore.apiConfig.asset.chainId,
      isEIP1559: true,
    );
    final r = sig.r.toRadixString(16).padLeft(64, '0');
    final s = sig.s.toRadixString(16).padLeft(64, '0');
    return BroadcastTransactionRequestDto(
      unsignedTx: rawTransaction,
      r: '0x$r',
      s: '0x$s',
      v: sig.v,
    );
  }

  void _acceptSoftwareQuote(RealUnitTransferPaymentInfoDto quote) {
    if (isClosed) {
      return;
    }
    _direction = MoveBalanceDirection.softwareToBitbox;
    _softwareQuote = quote;
    _hardwareQuote = null;
    _signedHardwareTx = null;
    _confirmSent = false;
    emit(
      MoveBalanceQuoteReady(
        direction: MoveBalanceDirection.softwareToBitbox,
        amount: quote.amount,
        networkFeeRealu: quote.networkFeeRealu,
        ethPaysGas: false,
        softwareBalance: _softwareBalance,
        bitboxBalance: _bitboxBalance,
      ),
    );
  }

  void _emitLocalFailure(MoveBalanceFailureReason reason) {
    _emitUnlessClosed(MoveBalanceFailure('', reason: reason));
  }

  void _emitUnlessClosed(MoveBalanceState next) {
    if (isClosed) {
      return;
    }
    emit(next);
  }
}
