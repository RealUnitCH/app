import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/dto/support_issue_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_reason.dart';
import 'package:realunit_wallet/packages/service/dfx/models/support/support_issue_type.dart';

class SupportService extends DFXAuthService {
  SupportService(super.appStore);

  @override
  get wallet => appStore.wallet.currentAccount;

  @override
  String get walletAddress => wallet.primaryAddress.address.hexEip55;

  Future<List<SupportIssueDto>> getTickets() async {
    final uri = buildUri(host, '/v1/support/issue');
    final authToken = await getAuthToken();

    final response = await appStore.httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      return jsonList
          .map((e) => SupportIssueDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load tickets: ${response.statusCode}');
    }
  }

  Future<SupportIssueDto> getTicket(String uid) async {
    final uri = buildUri(host, '/v1/support/issue/$uid');
    final authToken = await getAuthToken();

    final response = await appStore.httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      return SupportIssueDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load ticket: ${response.statusCode}');
    }
  }

  Future<SupportIssueDto> createTicket({
    required SupportIssueType type,
    required SupportIssueReason reason,
    required String name,
    String? message,
  }) async {
    final uri = buildUri(host, '/v1/support/issue');
    final authToken = await getAuthToken();

    final body = jsonEncode({
      'type': type.toJson(),
      'reason': reason.toJson(),
      'name': name,
      if (message != null) 'message': message,
    });

    final response = await appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: body,
    );

    if (response.statusCode == 201) {
      return SupportIssueDto.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to create ticket: ${response.statusCode}');
    }
  }

  Future<void> sendMessage(String ticketUid, String message) async {
    final uri = buildUri(host, '/v1/support/issue/$ticketUid/message');
    final authToken = await getAuthToken();

    final body = jsonEncode({'message': message});

    final response = await appStore.httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: body,
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }
}
