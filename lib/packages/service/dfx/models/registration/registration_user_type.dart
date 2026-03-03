import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';

enum RegistrationUserType {
  human(jsonName: 'HUMAN'),
  corporation(jsonName: 'CORPORATION')
  ;

  final String jsonName;

  const RegistrationUserType({required this.jsonName});

  String name(BuildContext context) {
    switch (this) {
      case RegistrationUserType.human:
        return S.of(context).accountTypeHuman;
      case RegistrationUserType.corporation:
        return S.of(context).accountTypeCorporation;
    }
  }

  factory RegistrationUserType.fromName(String name) {
    return RegistrationUserType.values.firstWhere(
      (e) => e.jsonName == name,
      orElse: () => throw ArgumentError('Unknown RegistrationUserType: $name'),
    );
  }
}
