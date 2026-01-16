import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';

enum RegistrationUserType {
  human(jsonName: 'HUMAN'),
  corporation(jsonName: 'CORPORATION');

  final String jsonName;

  String name(BuildContext context) {
    switch (this) {
      case RegistrationUserType.human:
        return S.of(context).accountTypeHuman;
      case RegistrationUserType.corporation:
        return S.of(context).accountTypeCorporation;
    }
  }

  const RegistrationUserType({required this.jsonName});
}
