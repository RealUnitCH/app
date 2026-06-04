import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/payment/transfer_exceptions.dart';
import 'package:web3dart/web3dart.dart' show EthereumAddress;

part 'send_recipient_state.dart';

/// Captures the transfer recipient — either scanned from a QR code or pasted /
/// typed manually. Validation here is a client-side UX guard only (a malformed
/// address is rejected before the user can advance); the API remains the final
/// authority on the address. A scanned `ethereum:0x…` URI is normalized to the
/// bare address so a wallet QR that encodes an EIP-681 URI is accepted.
class SendRecipientCubit extends Cubit<SendRecipientState> {
  SendRecipientCubit() : super(const SendRecipientEmpty());

  /// Called once per detected barcode while the scanner is open. Guards against
  /// re-entry after a successful decode so a continuously-detecting scanner does
  /// not re-emit.
  void onCodeDetected(String raw) {
    if (state is SendRecipientValid) return;
    submit(raw);
  }

  /// Validates a manually entered / pasted / scanned [input]. Emits
  /// [SendRecipientValid] with the checksummed address on success, or
  /// [SendRecipientInvalid] otherwise.
  void submit(String input) {
    final address = _extractAddress(input);
    try {
      final checksummed = EthereumAddress.fromHex(address).hexEip55;
      emit(SendRecipientValid(checksummed));
    } catch (_) {
      emit(SendRecipientInvalid(InvalidRecipientAddressException(input.trim())));
    }
  }

  /// Clears the current selection so the field/scanner is ready for new input.
  void reset() => emit(const SendRecipientEmpty());

  /// Strips an optional `ethereum:` EIP-681 scheme and any `@chainId` / query
  /// suffix, returning the bare hex address candidate.
  static String _extractAddress(String input) {
    var value = input.trim();
    if (value.toLowerCase().startsWith('ethereum:')) {
      value = value.substring('ethereum:'.length);
    }
    final at = value.indexOf('@');
    if (at != -1) value = value.substring(0, at);
    final query = value.indexOf('?');
    if (query != -1) value = value.substring(0, query);
    final slash = value.indexOf('/');
    if (slash != -1) value = value.substring(0, slash);
    return value.trim();
  }
}
