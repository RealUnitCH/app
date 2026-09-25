import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SNSMobileSDKStatus {
  Ready,
  Initial,
  Incomplete,
  Pending,
  Approved,
  Failed,
  FinallyRejected,
  TemporarilyDeclined,
  ActionCompleted
}

enum SNSMobileSDKErrorType {
  Unknown,
  InvalidParameters,
  Unauthorized,
  InitialLoadingFailed,
  ApplicantNotFound,
  ApplicantMisconfigured,
  NetworkError,
  UnexpectedError,
  InititlizationError,
}

enum SNSMobileSDKAnswerType {
  Unknown,
  Ignored,
  Red,
  Yellow,
  Green,
  Error,
}

enum SNSLogLevel {
  Error,
  Warning,
  Info,
  Debug,
  Verbose,
}

typedef SNSTokenExpirationHandler = Future<String?> Function();
typedef SNSReady = Function();
typedef SNSStatusChangedHandler = Function(SNSMobileSDKStatus newStatus, SNSMobileSDKStatus oldStatus);
typedef SNSEventHandler = Function(SNSMobileSDKEvent event);
typedef SNSLogHandler = Function(SNSLogLevel logLevel, String message);

class SNSMobileSDK {

  MethodChannel _channel = MethodChannel('sumsub.com/flutter_idensic_mobile_sdk_plugin');

  static SNSMobileSDKBuilder init(String? accessToken, SNSTokenExpirationHandler onTokenExpiration) {
    return SNSMobileSDKBuilder().withAccessToken(accessToken, onTokenExpiration);
  }

  final String? apiUrl;
  final String? accessToken;
  final Locale? locale;
  final Map<String, String>? applicantConf;
  final Map<String, String>? strings;
  final Map<String, dynamic>? preferredDocumentDefinitions;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? theme;
  final SNSTokenExpirationHandler? onTokenExpiration;
  final SNSStatusChangedHandler? onStatusChanged;
  final SNSEventHandler? onEvent;
  final SNSLogHandler? onLog;
  final bool isAnalyticsEnabled;
  final bool isDebug;
  final int autoCloseOnApprove;
  final String? supportEmail;

  SNSMobileSDK._builder(SNSMobileSDKBuilder builder) :
    apiUrl = builder.apiUrl,
    accessToken = builder.accessToken,
    locale = builder.locale,
    applicantConf = builder.applicantConf,
    preferredDocumentDefinitions = builder.preferredDocumentDefinitions,
    strings = builder.strings,
    settings = builder.settings,
    theme = builder.theme,
    onTokenExpiration = builder.onTokenExpiration,
    onStatusChanged = builder.onStatusChanged,
    onEvent = builder.onEvent,
    onLog = builder.onLog,
    isAnalyticsEnabled = builder.isAnalyticsEnabled,
    isDebug = builder.isDebug,
    autoCloseOnApprove = builder.autoCloseOnApprove,
    supportEmail = builder.supportEmail
    ;

  void dismiss() {
    _channel.invokeMethod('dismiss');
  }

  Future<SNSMobileSDKResult> launch() async {
    _channel.setMethodCallHandler(_onMethodCallHandler);
    final Map<dynamic, dynamic> map = await _channel.invokeMethod('onLaunchSDK', _toArguments()); // as FutureOr<Map<dynamic, dynamic>>);
    return Future.value(SNSMobileSDKResult.fromMap(map));
  }

  Future<String?> _onMethodCallHandler(MethodCall call) async {
    switch(call.method) {
      case "onLog":
        final SNSLogLevel? level = _toToLogLevel(call.arguments['level']);
        final String message = call.arguments['message'];

        if (level == null) {
          return null;
        }

        return onLog?.call(level, message);
      case "onTokenExpiration":
        return onTokenExpiration!();
      case "onError":
        return null;
      case "onStatusChanged":
        return onStatusChanged!(_toStatus(call.arguments[0]), _toStatus(call.arguments[1]));
      case "onEvent":
        return onEvent!(_toEvent(call.arguments[0]));
      default:
        print('Unknown method ${call.method}');
        throw MissingPluginException();
    }
  }

  Map<String, dynamic> _toArguments() {
    return {
      "apiUrl": apiUrl,
      "accessToken": accessToken,
      "languageCode": locale?.languageCode,
      "applicantConf": applicantConf,
      "preferredDocumentDefinitions": preferredDocumentDefinitions,
      "strings": strings,
      "settings": settings,
      "theme": theme,
      "isAnalyticsEnabled": isAnalyticsEnabled,
      "isDebug": isDebug,
      "hasOnStatusChanged": onStatusChanged != null,
      "hasOnEvent": onEvent != null,
      "hasOnLog": onLog != null,
      "autoCloseOnApprove": autoCloseOnApprove,
      "supportEmail": supportEmail,
    };
  }
}

class SNSMobileSDKBuilder {
  // builder
  String? apiUrl;
  String? accessToken;
  Locale? locale;
  String? supportEmail;
  Map<String, String>? applicantConf;
  Map<String, String>? strings;
  Map<String, dynamic>? settings;
  Map<String, dynamic>? preferredDocumentDefinitions;
  Map<String, dynamic>? theme;
  SNSTokenExpirationHandler? onTokenExpiration;
  SNSStatusChangedHandler? onStatusChanged;
  SNSEventHandler? onEvent;
  SNSLogHandler? onLog;
  bool isAnalyticsEnabled = true;
  bool isDebug = false;
  int autoCloseOnApprove = 3;

  SNSMobileSDKBuilder();

  SNSMobileSDKBuilder withAccessToken(String? accessToken, SNSTokenExpirationHandler onTokenExpiration) {
    this.accessToken = accessToken;
    this.onTokenExpiration = onTokenExpiration;
    return this;
  }

  SNSMobileSDKBuilder withLocale(Locale locale) {
    this.locale = locale;
    return this;
  }

  SNSMobileSDKBuilder withSupportEmail(String supportEmail) {
    this.supportEmail = supportEmail;
    return this;
  }

  SNSMobileSDKBuilder withSettings(Map<String, dynamic> settings) {
    this.settings = settings;
    return this;
  }

  SNSMobileSDKBuilder withPreferredDocumentDefinitions(Map<String, dynamic> preferredDocumentDefinitions) {
    this.preferredDocumentDefinitions = preferredDocumentDefinitions;
    return this;
  }

  SNSMobileSDKBuilder withApplicantConf(Map<String, String> applicantConf) {
    this.applicantConf = applicantConf;
    return this;
  }

  SNSMobileSDKBuilder withStrings(Map<String, String> strings) {
    this.strings = strings;
    return this;
  }

  SNSMobileSDKBuilder withTheme(Map<String, dynamic> theme) {
    this.theme = theme;
    return this;
  }

  SNSMobileSDKBuilder withHandlers({SNSStatusChangedHandler? onStatusChanged, SNSEventHandler? onEvent}) {
    this.onStatusChanged = onStatusChanged;
    this.onEvent = onEvent;
    return this;
  }

  SNSMobileSDKBuilder withAnalyticsEnabled(bool isAnalyticsEnabled) {
    this.isAnalyticsEnabled = isAnalyticsEnabled;
    return this;
  }

  SNSMobileSDKBuilder withDebug(bool isDebug) {
    this.isDebug = isDebug;
    return this;
  }

  SNSMobileSDKBuilder withBaseUrl(String apiUrl) {
    this.apiUrl = apiUrl;
    return this;
  }

  SNSMobileSDKBuilder withAutoCloseOnApprove(int autoCloseOnApprove) {
    this.autoCloseOnApprove = autoCloseOnApprove;
    return this;
  }

  SNSMobileSDKBuilder withLogHandler(SNSLogHandler logHandler) {
    this.onLog = logHandler;
    return this;
  }

  SNSMobileSDK build() {
    if (this.settings == null) {
      this.settings = new Map();
    }
    this.settings?["appFrameworkName"] = "flutter";

    return SNSMobileSDK._builder(this);
  }
}

class SNSMobileSDKResult {

  final bool success;
  final SNSMobileSDKStatus status;
  final SNSMobileSDKErrorType? errorType;
  final String? errorMsg;

  SNSMobileSDKResult(this.success, this.status, this.errorType, this.errorMsg);

  static SNSMobileSDKResult fromMap(Map<dynamic, dynamic> map) {

    return SNSMobileSDKResult(map['success'] as bool? ?? false, _toStatus(map['status']), _toErrorType(map['errorType']), map['errorMsg']);
  }

  String toString() => 'SNSMobileSDKResult(success: $success, status: $status, errorType: $errorType, errorMsg: $errorMsg)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is SNSMobileSDKResult &&
      o.success == success &&
      o.status == status &&
      o.errorType == errorType &&
      o.errorMsg == errorMsg;
  }

  @override
  int get hashCode {
    return success.hashCode ^
      status.hashCode ^
      errorType.hashCode ^
      errorMsg.hashCode;
  }
}

SNSMobileSDKStatus _toStatus(String? value) {
  SNSMobileSDKStatus status;
  switch (value) {
    case 'Ready':
      status = SNSMobileSDKStatus.Ready;
      break;
    case 'Initial':
      status = SNSMobileSDKStatus.Initial;
      break;
    case 'Incomplete':
      status = SNSMobileSDKStatus.Incomplete;
      break;
    case 'Pending':
      status = SNSMobileSDKStatus.Pending;
      break;
    case 'Approved':
      status = SNSMobileSDKStatus.Approved;
      break;
    case 'Failed':
      status = SNSMobileSDKStatus.Failed;
      break;
    case 'FinallyRejected':
      status = SNSMobileSDKStatus.FinallyRejected;
      break;
    case 'TemporarilyDeclined':
      status = SNSMobileSDKStatus.TemporarilyDeclined;
      break;
    case 'ActionCompleted':
      status = SNSMobileSDKStatus.ActionCompleted;
      break;
    default:
      throw new Exception("Unknown Status: $value");
  }

  return status;
}

SNSMobileSDKErrorType? _toErrorType(String? value) {

  if (value == null) {
    return null;
  }

  SNSMobileSDKErrorType errorType;
  switch (value) {
    case 'Unknown':
      errorType = SNSMobileSDKErrorType.Unknown;
      break;
    case 'InvalidParamaters':
      errorType = SNSMobileSDKErrorType.InvalidParameters;
      break;
    case 'Unauthorized':
      errorType = SNSMobileSDKErrorType.Unauthorized;
      break;
    case 'InitialLoadingFailed':
      errorType = SNSMobileSDKErrorType.InitialLoadingFailed;
      break;
    case 'ApplicantNotFound':
      errorType = SNSMobileSDKErrorType.ApplicantNotFound;
      break;
    case 'ApplicantMisconfigured':
      errorType = SNSMobileSDKErrorType.ApplicantMisconfigured;
      break;
    case 'NetworkError':
      errorType = SNSMobileSDKErrorType.NetworkError;
      break;
    case 'UnexpectedError':
      errorType = SNSMobileSDKErrorType.UnexpectedError;
      break;
    case 'InititlizationError':
      errorType = SNSMobileSDKErrorType.InititlizationError;
      break;
    default:
      throw new Exception("Unknown ErrorType: $value");
  }

  return errorType;
}

SNSLogLevel? _toToLogLevel(String level) {
  switch (level.toLowerCase()) {
    case "error":
      return SNSLogLevel.Error;
    case "warning":
      return SNSLogLevel.Warning;
    case "info":
      return SNSLogLevel.Info;
    case "debug":
      return SNSLogLevel.Debug;
    case "verbose":
      return SNSLogLevel.Verbose;
    default:
      return null;
  }
}

// ------
// Events
// ------

class SNSMobileSDKEvent {

  final String eventType;
  final Map<dynamic, dynamic> payload;

  SNSMobileSDKEvent(this.eventType, this.payload);

  String toString() => 'SNSMobileSDKEvent(eventType: $eventType, payload: $payload)';
}

SNSMobileSDKEvent _toEvent(Map<dynamic, dynamic> value) {

  return SNSMobileSDKEvent(value['eventType'] ?? "Unknown", value['payload'] ?? {});
}
