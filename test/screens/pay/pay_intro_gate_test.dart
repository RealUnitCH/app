import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/pay/pay_intro_gate.dart';

void main() {
  group('showPayIntro', () {
    test('a software wallet that has not seen the intro still sees it', () {
      expect(showPayIntro(payAllowed: true, alreadySeen: false), isTrue);
    });

    test('a software wallet that has seen the intro skips it', () {
      expect(showPayIntro(payAllowed: true, alreadySeen: true), isFalse);
    });

    test('a wallet that cannot pay still sees the notice', () {
      expect(showPayIntro(payAllowed: false, alreadySeen: false), isTrue);
      expect(showPayIntro(payAllowed: false, alreadySeen: true), isTrue);
    });
  });
}
