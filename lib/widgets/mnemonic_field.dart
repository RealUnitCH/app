// ignore: implementation_imports
import 'package:bip39/src/wordlists/english.dart' as wordlist;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realunit_wallet/styles/colors.dart';

part 'mnemonic_field_base.dart';
part 'mnemonic_input_field.dart';
part 'mnemonic_input_field_controller.dart';
part 'mnemonic_read_only_field.dart';

extension SeedStringExtension on String {
  List<String> get seedWords => trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
}

extension MnemonicListExtension on List<MnemonicInputFieldController> {
  String get seed => map((c) => c.text.trim()).join(' ');
}
