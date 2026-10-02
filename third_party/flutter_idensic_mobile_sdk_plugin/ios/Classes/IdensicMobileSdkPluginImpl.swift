import Flutter
import UIKit
import IdensicMobileSDK


public class IdensicMobileSdkPluginImpl: NSObject, FlutterPlugin {

    var channel: FlutterMethodChannel
    weak var sdk: SNSMobileSDK?

    public static func register(with registrar: FlutterPluginRegistrar) {

        let channel = FlutterMethodChannel(name: "sumsub.com/flutter_idensic_mobile_sdk_plugin",
                                           binaryMessenger: registrar.messenger())

        let instance = IdensicMobileSdkPluginImpl(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        if call.method == "dismiss" {
            self.sdk?.dismiss()
            return
        }

        if call.method != "onLaunchSDK" {
            result(FlutterMethodNotImplemented)
            return
        }

        let channel = self.channel

        let args = call.arguments as? Dictionary<String, Any>
        let baseUrl = args?["apiUrl"] as? String ?? ""
        let accessToken = args?["accessToken"] as? String ?? ""
        let locale = args?["languageCode"] as? String ?? ""
        let isDebug = args?["isDebug"] as? Bool ?? false
        let isAnalyticsEnabled = args?["isAnalyticsEnabled"] as? Bool ?? true
        let hasOnStatusChanged = args?["hasOnStatusChanged"] as? Bool ?? false
        let hasOnEvent = args?["hasOnEvent"] as? Bool ?? false
        let hasOnLog = args?["hasOnLog"] as? Bool ?? false
        let applicantConf = args?["applicantConf"] as? Dictionary<String, String>
        let strings = args?["strings"] as? Dictionary<String, String>
        let settings = args?["settings"] as? Dictionary<String, Any>
        let preferredDocumentDefinitions = args?["preferredDocumentDefinitions"] as? Dictionary<String, Any>
        let autoCloseOnApprove = args?["autoCloseOnApprove"] as? TimeInterval

        let environment = !baseUrl.isEmpty ? SNSEnvironment(baseUrl) : SNSEnvironment.production;

        let sdk = SNSMobileSDK(
            accessToken: accessToken,
            environment: environment
        )

        if !locale.isEmpty {
            sdk.locale = locale
        }

        guard sdk.isReady else {
            result(sdk.pluginResult)
            return
        }

        self.sdk = sdk

        if isDebug {
            sdk.logLevel = .debug
        }

        if !isAnalyticsEnabled {
            sdk.isAnalyticsEnabled = false
        }

        if let autoCloseOnApprove = autoCloseOnApprove {
            sdk.setOnApproveDismissalTimeInterval(autoCloseOnApprove)
        }

        if let strings = strings {
            sdk.strings = strings
        }

        if let settings = settings {
            sdk.settings = settings
        }

        if let email = applicantConf?["email"] {
            sdk.initialEmail = email
        }
        if let phone = applicantConf?["phone"] {
            sdk.initialPhone = phone
        }

        // Upstream 1.42.0 stores supportEmail and never forwards it. Replace the
        // dashboard mailto item so this app does not offer that account address.
        if let supportEmail = args?["supportEmail"] as? String,
           !supportEmail.isEmpty,
           let url = URL(string: "mailto:\(supportEmail)") {
            var replaced = false
            for item in sdk.supportItems ?? [] {
                if item.actionURL == nil || item.actionURL?.scheme == "mailto" {
                    item.actionURL = url
                    replaced = true
                }
            }
            if !replaced {
                sdk.supportItems = []
                sdk.addSupportItem { item in
                    item.title = "Support"
                    item.actionURL = url
                }
            }
        }

        if let preferredDocumentDefinitions = preferredDocumentDefinitions {
            sdk.setPreferredDocumentDefinitions(json: preferredDocumentDefinitions)
        }

        sdk.tokenExpirationHandler { (onComplete) in
            channel.invokeMethod("onTokenExpiration", arguments: nil) { (newToken) in
                onComplete(newToken as? String)
            }
        }

        if hasOnStatusChanged {
            sdk.onStatusDidChange { (sdk, prevStatus) in
                channel.invokeMethod("onStatusChanged", arguments: [
                    sdk.description(for: sdk.status),
                    sdk.description(for: prevStatus)
                ])
            }
        }

        if hasOnEvent {
            sdk.onEvent { (sdk, event) in
                channel.invokeMethod("onEvent", arguments: [event.asDict])
            }
        }

       if hasOnLog {
            sdk.logHandler { (level, message) in
                guard let logLevel = level.asPluginLogLevel else {
                    return
                }

                channel.invokeMethod("onLog", arguments: [
                    "level": logLevel,
                    "message": message,
                ])
            }
        }

        sdk.onDidDismiss { (sdk) in
            result(sdk.pluginResult)
        }

        if let theme = args?["theme"] as? [String:Any] {
            sdk.theme = SNSTheme(
                fromJSON: theme,
                assetsPath: FlutterDartProject.lookupKey(forAsset: ""),
                assetNameHandler: { assetName in
                    return assetName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                }
            )
        }

        applyCustomizationIfAny()

        sdk.present()
    }
}

private extension SNSLogLevel {

    var asPluginLogLevel: String? {
        switch self {
        case .off:
            return nil
        case .error:
            return "Error"
        case .warning:
            return "Warning"
        case .info:
            return "Info"
        case .debug:
            return "Debug"
        case .trace:
            return "Verbose"
        @unknown default:
            return nil
        }
    }
}

extension IdensicMobileSdkPluginImpl {

    /**
     * Usage:
     *
     * Add a class named `IdensicMobileSDKCustomization` into the main project
     * and define a static method named `apply:` that will take an instance of `SNSMobileSDK`
     *
     * For example, in Swift:
     *
     * import IdensicMobileSDK
     *
     * class IdensicMobileSDKCustomization: NSObject {
     *   @objc static func apply(_ sdk: SNSMobileSDK) {
     *   }
     * }
     *
     */

    func applyCustomizationIfAny() {

        let className = "IdensicMobileSDKCustomization"
        let selector = Selector(("apply:"))

        var customization: AnyClass? = Bundle.main.classNamed(className)
        if customization == nil {
            if let classPrefix = Bundle.main.object(forInfoDictionaryKey: kCFBundleExecutableKey as String) {
                customization = Bundle.main.classNamed("\(classPrefix).\(className)")
            }
        }

        if let customization = customization as? NSObject.Type, customization.responds(to: selector) {
            customization.perform(selector, with: sdk)
        }
    }
}

typealias Dict = [String:Any]

extension SNSMobileSDK {

    var pluginResult: Dict {

        var result = Dict()

        result["success"] = status != .failed
        result["status"] = description(for: status)

        if (status == .failed) {
            result["errorType"] = description(for: failReason)
            result["errorMsg"] = verboseStatus
        }

        return result
    }
}

extension SNSEvent {

    var asDict: Dict {

        var result = Dict()

        result["eventType"] = description(for: eventType)
        result["payload"] = payload

        return result
    }
}
