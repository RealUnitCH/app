import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_confirm_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/payment/sell/dto/eip7702/eip7702_data_dto.dart';

void main() {
  group('$Eip7702Domain.fromJson', () {
    test('parses name + version + chainId + verifyingContract', () {
      final dto = Eip7702Domain.fromJson({
        'name': 'RealUnit',
        'version': '1',
        'chainId': 1,
        'verifyingContract': '0xverify',
      });

      expect(dto.name, 'RealUnit');
      expect(dto.version, '1');
      expect(dto.chainId, 1);
      expect(dto.verifyingContract, '0xverify');
    });
  });

  group('$Eip7702TypeField.fromJson', () {
    test('parses name + type', () {
      final dto = Eip7702TypeField.fromJson({'name': 'delegate', 'type': 'address'});

      expect(dto.name, 'delegate');
      expect(dto.type, 'address');
    });
  });

  group('$Eip7702Types.fromJson', () {
    test('parses Delegation + Caveat field lists', () {
      final dto = Eip7702Types.fromJson({
        'Delegation': [
          {'name': 'delegate', 'type': 'address'},
          {'name': 'delegator', 'type': 'address'},
        ],
        'Caveat': [
          {'name': 'authority', 'type': 'address'},
        ],
      });

      expect(dto.delegation, hasLength(2));
      expect(dto.delegation.first.name, 'delegate');
      expect(dto.caveat, hasLength(1));
      expect(dto.caveat.first.name, 'authority');
    });
  });

  group('$Eip7702Message.fromJson', () {
    test('parses every field including the caveats list', () {
      final dto = Eip7702Message.fromJson({
        'delegate': '0xd',
        'delegator': '0xdr',
        'authority': '0xauth',
        'caveats': [
          {'enforcer': '0xenf'},
        ],
        'salt': 42,
      });

      expect(dto.delegate, '0xd');
      expect(dto.delegator, '0xdr');
      expect(dto.authority, '0xauth');
      expect(dto.caveats, hasLength(1));
      expect(dto.salt, 42);
    });
  });

  group('$Eip7702Data.fromJson', () {
    final fullJson = {
      'relayerAddress': '0xrelay',
      'delegationManagerAddress': '0xmgr',
      'delegatorAddress': '0xdr',
      'userNonce': 7,
      'domain': {
        'name': 'RealUnit',
        'version': '1',
        'chainId': 1,
        'verifyingContract': '0xverify',
      },
      'types': {
        'Delegation': <Map<String, dynamic>>[],
        'Caveat': <Map<String, dynamic>>[],
      },
      'message': {
        'delegate': '0xd',
        'delegator': '0xdr',
        'authority': '0xauth',
        'caveats': <Map<String, dynamic>>[],
        'salt': 0,
      },
      'tokenAddress': '0xtoken',
      'amountWei': '12345',
      'depositAddress': '0xdeposit',
    };

    test('parses every top-level field and recurses into the nested DTOs', () {
      final dto = Eip7702Data.fromJson(fullJson);

      expect(dto.relayerAddress, '0xrelay');
      expect(dto.delegationManagerAddress, '0xmgr');
      expect(dto.delegatorAddress, '0xdr');
      expect(dto.userNonce, 7);
      expect(dto.domain.chainId, 1);
      expect(dto.types.delegation, isEmpty);
      expect(dto.message.delegate, '0xd');
      expect(dto.tokenAddress, '0xtoken');
      expect(dto.amountWei, '12345');
      expect(dto.depositAddress, '0xdeposit');
    });
  });

  group('$Eip7702AuthorizationDto.toJson', () {
    test('round-trips the six fields (chainId / nonce kept as dynamic)', () {
      final dto = Eip7702AuthorizationDto(
        chainId: 1,
        address: '0xa',
        nonce: 0,
        r: '0xr',
        s: '0xs',
        yParity: 0,
      );

      expect(dto.toJson(), {
        'chainId': 1,
        'address': '0xa',
        'nonce': 0,
        'r': '0xr',
        's': '0xs',
        'yParity': 0,
      });
    });

    test('accepts string chainId / nonce (the comment says number or string)', () {
      final dto = Eip7702AuthorizationDto(
        chainId: '0x1',
        address: '0xa',
        nonce: '0',
        r: '0xr',
        s: '0xs',
        yParity: 1,
      );

      final json = dto.toJson();
      expect(json['chainId'], '0x1');
      expect(json['nonce'], '0');
    });
  });

  group('$Eip7702ConfirmDto.toJson', () {
    test('serialises nested delegation + authorization', () {
      final delegation = Eip7702DelegationDto(
        delegate: '0xd',
        delegator: '0xdr',
        authority: '0xauth',
        salt: '0',
        signature: '0xsig',
      );
      final authorization = Eip7702AuthorizationDto(
        chainId: 1,
        address: '0xa',
        nonce: 0,
        r: '0xr',
        s: '0xs',
        yParity: 0,
      );

      final dto = Eip7702ConfirmDto(
        delegation: delegation,
        authorization: authorization,
      );
      final json = dto.toJson();

      expect(json['delegation'], delegation.toJson());
      expect(json['authorization'], authorization.toJson());
    });
  });
}
