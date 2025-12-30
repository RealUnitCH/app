import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';

enum DfxUserType {
  human(jsonName: 'HUMAN'),
  corporation(jsonName: 'CORPORATION');

  final String jsonName;

  String name(BuildContext context) {
    switch (this) {
      case DfxUserType.human:
        return S.of(context).account_type_human;
      case DfxUserType.corporation:
        return S.of(context).account_type_corporation;
    }
  }

  const DfxUserType({required this.jsonName});
}
