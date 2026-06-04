import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/send/cubits/send_recipient/send_recipient_cubit.dart';

void main() {
  // A valid EVM address and its EIP-55 checksum form.
  const lowercase = '0x9f5713deacb8e9cab6c2d3fae1afc2715f8d2d71';
  const checksummed = '0x9F5713DEacB8e9CAB6c2d3FaE1AFc2715F8D2D71';

  group('SendRecipientCubit', () {
    test('starts empty', () {
      expect(SendRecipientCubit().state, isA<SendRecipientEmpty>());
    });

    blocTest<SendRecipientCubit, SendRecipientState>(
      'a valid address is normalized to its EIP-55 checksum',
      build: SendRecipientCubit.new,
      act: (cubit) => cubit.submit(lowercase),
      verify: (cubit) {
        final state = cubit.state as SendRecipientValid;
        expect(state.address, checksummed);
      },
    );

    blocTest<SendRecipientCubit, SendRecipientState>(
      'trims surrounding whitespace before validating',
      build: SendRecipientCubit.new,
      act: (cubit) => cubit.submit('  $checksummed  '),
      expect: () => [const SendRecipientValid(checksummed)],
    );

    blocTest<SendRecipientCubit, SendRecipientState>(
      'strips an ethereum: EIP-681 scheme and @chainId / query suffix',
      build: SendRecipientCubit.new,
      act: (cubit) => cubit.submit('ethereum:$lowercase@1?value=0'),
      expect: () => [const SendRecipientValid(checksummed)],
    );

    blocTest<SendRecipientCubit, SendRecipientState>(
      'an invalid address emits SendRecipientInvalid',
      build: SendRecipientCubit.new,
      act: (cubit) => cubit.submit('not-an-address'),
      expect: () => [isA<SendRecipientInvalid>()],
    );

    blocTest<SendRecipientCubit, SendRecipientState>(
      'onCodeDetected decodes a scanned address like submit',
      build: SendRecipientCubit.new,
      act: (cubit) => cubit.onCodeDetected(checksummed),
      expect: () => [const SendRecipientValid(checksummed)],
    );

    blocTest<SendRecipientCubit, SendRecipientState>(
      'onCodeDetected ignores further detections once valid (no re-emit)',
      build: SendRecipientCubit.new,
      act: (cubit) {
        cubit.onCodeDetected(checksummed);
        cubit.onCodeDetected(checksummed);
      },
      expect: () => [const SendRecipientValid(checksummed)],
    );

    blocTest<SendRecipientCubit, SendRecipientState>(
      'reset returns to empty',
      build: SendRecipientCubit.new,
      act: (cubit) {
        cubit.submit(checksummed);
        cubit.reset();
      },
      expect: () => [const SendRecipientValid(checksummed), const SendRecipientEmpty()],
    );
  });
}
