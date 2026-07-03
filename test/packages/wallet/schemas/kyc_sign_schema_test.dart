import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/wallet/exceptions/eip712_schema_drift_exception.dart';
import 'package:realunit_wallet/packages/wallet/schemas/kyc_sign_schema.dart';

void main() {
  group('KycSignSchema', () {
    test('primary type, version and fields are pinned', () {
      final schemaFactory = KycSignSchema.new;
      final schema = schemaFactory();
      expect(schema.schemaVersion, 'kyc/v1');
      expect(schema.primaryType, 'RealUnitKyc');
      expect(schema.types['EIP712Domain']!.map((f) => '${f.name}:${f.type}'), [
        'name:string',
        'version:string',
        'chainId:uint256',
        'verifyingContract:address',
      ]);
      expect(schema.types['RealUnitKyc']!.map((f) => '${f.name}:${f.type}'), [
        'accountType:string',
        'firstName:string',
        'lastName:string',
        'phone:string',
        'addressStreet:string',
        'addressHouseNumber:string',
        'addressZip:string',
        'addressCity:string',
        'addressCountry:uint256',
        'walletAddress:address',
        'registrationDate:string',
      ]);
    });

    test('accepts the byte-equal client-pinned schema', () {
      final schemaFactory = KycSignSchema.new;
      final schema = schemaFactory();
      final backend = jsonDecode(jsonEncode(schema.typesAsJson())) as Map<String, dynamic>;
      expect(() => schema.validate(backend), returnsNormally);
    });

    test('rejects backend shape drift', () {
      final schemaFactory = KycSignSchema.new;
      final schema = schemaFactory();
      final backend = jsonDecode(jsonEncode(schema.typesAsJson())) as Map<String, dynamic>;
      final kyc = (backend['RealUnitKyc'] as List).cast<Map<String, dynamic>>();
      kyc.add({'name': 'hiddenApproval', 'type': 'uint256'});
      backend['RealUnitKyc'] = kyc;
      expect(
        () => schema.validate(backend),
        throwsA(
          isA<Eip712SchemaDriftException>().having(
            (e) => e.driftedField,
            'driftedField',
            'RealUnitKyc',
          ),
        ),
      );
    });
  });
}
