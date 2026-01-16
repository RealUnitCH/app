import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

final frontendCode = Uint8List.fromList(sha256.convert(utf8.encode('wallet')).bytes);
