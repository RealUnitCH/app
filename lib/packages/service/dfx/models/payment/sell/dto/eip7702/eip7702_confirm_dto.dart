class Eip7702DelegationDto {
  final String delegate;
  final String delegator;
  final String authority;
  final String salt;
  final String signature;

  Eip7702DelegationDto({
    required this.delegate,
    required this.delegator,
    required this.authority,
    required this.salt,
    required this.signature,
  });

  Map<String, dynamic> toJson() {
    return {
      'delegate': delegate,
      'delegator': delegator,
      'authority': authority,
      'salt': salt,
      'signature': signature,
    };
  }
}

class Eip7702AuthorizationDto {
  final dynamic chainId; // number or string
  final String address;
  final dynamic nonce; // number or string
  final String r;
  final String s;
  final int yParity;

  Eip7702AuthorizationDto({
    required this.chainId,
    required this.address,
    required this.nonce,
    required this.r,
    required this.s,
    required this.yParity,
  });

  Map<String, dynamic> toJson() {
    return {
      'chainId': chainId,
      'address': address,
      'nonce': nonce,
      'r': r,
      's': s,
      'yParity': yParity,
    };
  }
}

class Eip7702ConfirmDto {
  final Eip7702DelegationDto delegation;
  final Eip7702AuthorizationDto authorization;

  Eip7702ConfirmDto({
    required this.delegation,
    required this.authorization,
  });

  Map<String, dynamic> toJson() {
    return {
      'delegation': delegation.toJson(),
      'authorization': authorization.toJson(),
    };
  }
}
