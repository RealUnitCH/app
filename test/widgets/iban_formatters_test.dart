import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/iban_input_formatter.dart';
import 'package:realunit_wallet/widgets/iban_text_formatter.dart';

void main() {
  group('$IbanTextFormatter.formatIban', () {
    test('empty input returns empty string', () {
      expect(IbanTextFormatter.formatIban(''), '');
    });

    test('uppercases lowercase characters', () {
      expect(IbanTextFormatter.formatIban('ch93'), 'CH93');
    });

    test('strips existing spaces before regrouping', () {
      expect(IbanTextFormatter.formatIban('CH 93 008'), 'CH93 008');
    });

    test('groups long input every four characters', () {
      expect(
        IbanTextFormatter.formatIban('CH9300762011623852957'),
        'CH93 0076 2011 6238 5295 7',
      );
    });

    test('exactly four characters: no trailing space', () {
      expect(IbanTextFormatter.formatIban('CHFR'), 'CHFR');
    });
  });

  group('$IbanInputFormatter.formatEditUpdate', () {
    final formatter = IbanInputFormatter();

    TextEditingValue update(String input) => formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: input),
        );

    test('groups output in fours and uppercases', () {
      final out = update('ch93007620116238');
      expect(out.text, 'CH93 0076 2011 6238');
    });

    test('drops invalid characters silently', () {
      final out = update('CH 93-0076.2011');
      expect(out.text, 'CH93 0076 2011');
    });

    test('keeps the caret collapsed at the end of the formatted text', () {
      final out = update('CH9300762011');
      expect(out.text, 'CH93 0076 2011');
      expect(out.selection, TextSelection.collapsed(offset: out.text.length));
      expect(out.composing, TextRange.empty);
    });

    test('empty input remains empty', () {
      final out = update('');
      expect(out.text, '');
      expect(out.selection.baseOffset, 0);
    });
  });
}
