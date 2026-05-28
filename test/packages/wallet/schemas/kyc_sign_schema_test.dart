// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/schemas/kyc_sign_schema.dart';

void main() {
  group('KycSignSchema', () {
    test('runtime constructor exposes the pinned primary type and version', () {
      final schema = KycSignSchema();

      expect(schema.schemaVersion, 'kyc/v1');
      expect(schema.primaryType, 'RealUnitKyc');
    });

    test('byte-stable JSON representation', () {
      final schema = KycSignSchema();

      expect(
        jsonEncode(schema.typesAsJson()),
        '{"EIP712Domain":'
        '[{"name":"name","type":"string"},'
        '{"name":"version","type":"string"},'
        '{"name":"chainId","type":"uint256"},'
        '{"name":"verifyingContract","type":"address"}],'
        '"RealUnitKyc":'
        '[{"name":"accountType","type":"string"},'
        '{"name":"firstName","type":"string"},'
        '{"name":"lastName","type":"string"},'
        '{"name":"phone","type":"string"},'
        '{"name":"addressStreet","type":"string"},'
        '{"name":"addressHouseNumber","type":"string"},'
        '{"name":"addressZip","type":"string"},'
        '{"name":"addressCity","type":"string"},'
        '{"name":"addressCountry","type":"uint256"},'
        '{"name":"walletAddress","type":"address"},'
        '{"name":"registrationDate","type":"string"}]}',
      );
    });
  });
}
