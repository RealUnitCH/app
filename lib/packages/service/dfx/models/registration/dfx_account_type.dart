import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';

enum DfxAccountType {
  human(jsonName: 'HUMAN'),
  corporation(jsonName: 'CORPORATION');

  final String jsonName;

  String name(BuildContext context) {
    switch (this) {
      case DfxAccountType.human:
        return S.of(context).account_type_human;
      case DfxAccountType.corporation:
        return S.of(context).account_type_corporation;
    }
  }

  const DfxAccountType({required this.jsonName});
}
