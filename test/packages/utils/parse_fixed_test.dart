import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/utils/parse_fixed.dart';

void main() {
  group('parseFixed', () {
    test('should parse 1 into 1000000', () => expect(parseFixed('1', 6), BigInt.parse('1000000')));

    test('should parse 1.1 into 1100000',
        () => expect(parseFixed('1.1', 6), BigInt.parse('1100000')));

    test('should parse 1.100000 into 1100000',
        () => expect(parseFixed('1.100000', 6), BigInt.parse('1100000')));

    test('should parse 1.000001 into 1000001',
        () => expect(parseFixed('1.000001', 6), BigInt.parse('1000001')));

    test(
        'should parse 1. into 1000000', () => expect(parseFixed('1.', 6), BigInt.parse('1000000')));

    test('should parse -1 into -1000000',
        () => expect(parseFixed('-1', 6), BigInt.parse('-1000000')));

    test('should fail to parse 1.1000001, do many decimals',
        () => expect(() => parseFixed('1.1000001', 6), throwsException));

    test('should fail to parse .1, no whole number',
        () => expect(() => parseFixed('.1', 6), throwsException));

    test('empty string throws', () => expect(() => parseFixed('', 6), throwsA(anything)));

    test('multiple decimal points throws',
        () => expect(() => parseFixed('1.2.3', 6), throwsA(isA<Exception>())));

    test('just a dot throws', () => expect(() => parseFixed('.', 6), throwsA(isA<Exception>())));

    test('zero returns BigInt.zero', () => expect(parseFixed('0', 6), BigInt.zero));
  });
}
