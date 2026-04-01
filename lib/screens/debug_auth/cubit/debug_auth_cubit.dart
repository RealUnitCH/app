import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/app_store.dart';

part 'debug_auth_state.dart';

class DebugAuthCubit extends Cubit<DebugAuthState> {
  final AppStore _appStore;
  final SharedPreferences _prefs;

  static const _addressKey = 'debugAuthAddress';
  static const _signatureKey = 'debugAuthSignature';

  DebugAuthCubit(this._appStore, this._prefs)
      : super(DebugAuthState(
          address: _prefs.getString(_addressKey) ?? '',
          savedSignature: _prefs.getString(_signatureKey),
        ));

  String get _host => _appStore.apiConfig.apiHost;

  Future<void> fetchSignMessage(String address) async {
    emit(state.copyWith(address: address, isLoading: true));

    try {
      final uri = buildUri(_host, '/v1/auth/signMessage', {'address': address});
      final response = await _appStore.httpClient.get(uri, headers: {'accept': 'application/json'});

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        emit(state.copyWith(signMessage: body['message'] as String, isLoading: false));
      } else {
        emit(state.copyWith(
          errorMessage: 'Failed to fetch sign message (${response.statusCode})',
          isLoading: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString(), isLoading: false));
    }
  }

  Future<void> authenticate(String signature) async {
    emit(state.copyWith(isLoading: true));

    try {
      final uri = buildUri(_host, '/v1/auth');
      final response = await _appStore.httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'wallet': 'RealUnit',
          'address': state.address,
          'signature': signature,
        }),
      );

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _appStore.dfxAuthToken = body['accessToken'] as String;
        _appStore.debugAddress = state.address;
        _prefs.setString(_addressKey, state.address);
        _prefs.setString(_signatureKey, signature);
        emit(state.copyWith(isAuthenticated: true, isLoading: false));
      } else {
        emit(state.copyWith(
          errorMessage: 'Auth failed (${response.statusCode}): ${response.body}',
          isLoading: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString(), isLoading: false));
    }
  }
}
