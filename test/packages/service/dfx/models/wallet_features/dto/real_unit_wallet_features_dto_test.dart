import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/wallet_features/dto/real_unit_wallet_features_dto.dart';

void main() {
  group('$RealUnitWalletFeaturesDto.fromJson', () {
    test('reads JSON true as true', () {
      const json = {
        'pay': true,
        'send': true,
        'promoCode': true,
        'referral': true,
      };

      final dto = RealUnitWalletFeaturesDto.fromJson(json);

      expect(dto.pay, isTrue);
      expect(dto.send, isTrue);
      expect(dto.promoCode, isTrue);
      expect(dto.referral, isTrue);
    });

    test('reads JSON false as false', () {
      const json = {
        'pay': false,
        'send': false,
        'promoCode': false,
        'referral': false,
      };

      final dto = RealUnitWalletFeaturesDto.fromJson(json);

      expect(dto.pay, isFalse);
      expect(dto.send, isFalse);
      expect(dto.promoCode, isFalse);
      expect(dto.referral, isFalse);
    });

    test('treats missing keys as false', () {
      final dto = RealUnitWalletFeaturesDto.fromJson(const <String, dynamic>{});

      expect(dto.pay, isFalse);
      expect(dto.send, isFalse);
      expect(dto.promoCode, isFalse);
      expect(dto.referral, isFalse);
    });

    test('treats non-boolean values as false without throwing', () {
      const json = {
        'pay': 'true',
        'send': 1,
        'promoCode': '1',
        'referral': true,
      };

      final dto = RealUnitWalletFeaturesDto.fromJson(json);

      expect(dto.pay, isFalse);
      expect(dto.send, isFalse);
      expect(dto.promoCode, isFalse);
      expect(dto.referral, isTrue);
    });

    test('treats null values as false', () {
      const json = {
        'pay': null,
        'send': null,
        'promoCode': null,
        'referral': null,
      };

      final dto = RealUnitWalletFeaturesDto.fromJson(json);

      expect(dto.pay, isFalse);
      expect(dto.send, isFalse);
      expect(dto.promoCode, isFalse);
      expect(dto.referral, isFalse);
    });
  });
}
