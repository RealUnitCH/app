import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';

part 'registration_email_verification_step_state.dart';

class RegistrationEmailVerificationStepCubit extends Cubit<RegistrationEmailVerificationStepState> {
  final DFXAuthService _dfxService;

  RegistrationEmailVerificationStepCubit({required DFXAuthService dfxService})
      : _dfxService = dfxService,
        super(RegistrationEmailVerificationStepInitial());

  Future<void> checkEmailVerification() async {
    emit(RegistrationEmailVerificationStepLoading());

    final currentToken = await _dfxService.getAuthToken();
    if (currentToken == null) return;
    final currentJwt = parseJwt(currentToken);

    _dfxService.invalidateAuthToken();
    final newToken = await _dfxService.getAuthToken();
    if (newToken == null) return;
    final newJwt = parseJwt(currentToken);

    if (currentJwt['account'] as int != newJwt['account'] as int) {
      emit(RegistrationEmailVerificationStepSuccess());
    } else {
      emit(const RegistrationEmailVerificationStepFailure('The Mail was not confirmed'));
    }
  }
}

Map<String, dynamic> parseJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('invalid token');
  }

  final payload = _decodeBase64(parts[1]);
  final payloadMap = json.decode(payload);
  if (payloadMap is! Map<String, dynamic>) {
    throw Exception('invalid payload');
  }

  return payloadMap;
}

String _decodeBase64(String str) {
  String output = str.replaceAll('-', '+').replaceAll('_', '/');

  switch (output.length % 4) {
    case 0:
      break;
    case 2:
      output += '==';
      break;
    case 3:
      output += '=';
      break;
    default:
      throw Exception('Illegal base64url string!"');
  }

  return utf8.decode(base64Url.decode(output));
}
