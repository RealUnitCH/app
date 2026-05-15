import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/widgets/mnemonic_field.dart';

void main() {
  group('SeedStringExtension.seedWords', () {
    test('splits on single spaces', () {
      expect(
        'abandon ability about'.seedWords,
        ['abandon', 'ability', 'about'],
      );
    });

    test('collapses repeated whitespace and tabs', () {
      expect(
        'abandon   ability\tabout'.seedWords,
        ['abandon', 'ability', 'about'],
      );
    });

    test('strips leading + trailing whitespace', () {
      expect(
        '   abandon ability   '.seedWords,
        ['abandon', 'ability'],
      );
    });

    test('newlines count as whitespace', () {
      expect(
        'abandon\nability\nabout'.seedWords,
        ['abandon', 'ability', 'about'],
      );
    });

    test('empty input returns empty list', () {
      expect(''.seedWords, isEmpty);
      expect('   '.seedWords, isEmpty);
    });
  });

  group('MnemonicListExtension.seed', () {
    test('joins controller texts with single spaces and trims each entry', () {
      // Build a list of MnemonicInputFieldController and seed them.
      final controllers = List.generate(3, (_) => MnemonicInputFieldController());
      controllers[0].text = '  abandon';
      controllers[1].text = 'ability ';
      controllers[2].text = 'about';

      expect(controllers.seed, 'abandon ability about');

      for (final c in controllers) {
        c.dispose();
      }
    });

    test('preserves the controller order', () {
      final controllers = List.generate(3, (_) => MnemonicInputFieldController());
      controllers[0].text = 'one';
      controllers[1].text = 'two';
      controllers[2].text = 'three';

      expect(controllers.seed, 'one two three');

      for (final c in controllers) {
        c.dispose();
      }
    });
  });

  group('$MnemonicInputFieldController.buildTextSpan', () {
    // The bip39 wordlist contains "abandon" but not "xyz".
    final ctx = _StubContext();

    test('returns the base style for a word that is in the BIP39 list', () {
      final c = MnemonicInputFieldController()..text = 'abandon';
      const baseStyle = TextStyle(fontSize: 16);

      final span = c.buildTextSpan(context: ctx, style: baseStyle, withComposing: false);

      expect(span.text, 'abandon');
      expect(span.style, baseStyle);
      c.dispose();
    });

    test('merges in the red non-match style for an unknown word', () {
      final c = MnemonicInputFieldController()..text = 'xyzzyabcd';
      const baseStyle = TextStyle(fontSize: 16);

      final span = c.buildTextSpan(context: ctx, style: baseStyle, withComposing: false);

      // The merged style retains the base font size but adopts the red color.
      expect(span.style!.fontSize, 16);
      expect(span.style!.color, isNot(isNull));
      c.dispose();
    });
  });
}

class _StubContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
