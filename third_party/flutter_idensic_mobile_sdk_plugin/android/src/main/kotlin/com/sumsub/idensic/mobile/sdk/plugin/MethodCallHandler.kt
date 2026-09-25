package com.sumsub.idensic.mobile.sdk.plugin

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.os.Handler
import android.util.Log
import com.sumsub.idensic.mobile.sdk.plugin.bridge.SNSPluginRemoteMethodBridge
import com.sumsub.idensic.mobile.sdk.plugin.extension.withLogTree
import com.sumsub.idensic.mobile.sdk.plugin.logger.FlutterLoggerAdapter
import com.sumsub.idensic.mobile.sdk.plugin.logger.SNSLogLevel
import com.sumsub.sns.core.SNSMobileSDK
import com.sumsub.sns.core.SNSModule
import com.sumsub.sns.core.SNSProoface
import com.sumsub.sns.core.data.listener.SNSCompleteHandler
import com.sumsub.sns.core.data.listener.SNSErrorHandler
import com.sumsub.sns.core.data.listener.SNSEvent
import com.sumsub.sns.core.data.listener.SNSEventHandler
import com.sumsub.sns.core.data.listener.SNSStateChangedHandler
import com.sumsub.sns.core.data.listener.TokenExpirationHandler
import com.sumsub.sns.core.data.model.SNSCompletionResult
import com.sumsub.sns.core.data.model.SNSDocumentDefinition
import com.sumsub.sns.core.data.model.SNSException
import com.sumsub.sns.core.data.model.SNSInitConfig
import com.sumsub.sns.core.data.model.SNSSupportItem
import com.sumsub.sns.core.data.model.SNSSDKState
import com.sumsub.sns.core.theme.SNSCustomizationFileFormat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeoutOrNull
import java.util.Locale
import java.util.concurrent.TimeoutException
import kotlin.time.Duration.Companion.seconds

class MethodCallHandler : MethodChannel.MethodCallHandler {

    var ctx: Context? = null
        set(value) {
            field = value
            if (value == null) {
                mainHandler?.removeCallbacksAndMessages(null)
                mainHandler = null
                Log.v(TAG, "callback Handler removed ")
            } else {
                mainHandler = Handler(value.mainLooper)
                Log.v(TAG, "callback Handler created ")
            }
        }
    private var mainHandler: Handler? = null

    var methodChannel: MethodChannel? = null
        private set
    private var snsSdk: SNSMobileSDK.SDK? = null

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val activityHolder = MutableStateFlow<Activity?>(null)

    private var sdkLaunchAsyncJob: Job? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val remoteMethodBridge = SNSPluginRemoteMethodBridge { methodChannel }

        when (call.method) {
            "dismiss" -> {
                snsSdk?.dismiss()
                clear()
            }

            "onLaunchSDK" -> {
                Log.v(TAG, "onLaunchSDK: ...")

                val activity = activityHolder.value

                if (activity != null) {
                    Log.v(TAG, "onLaunchSDK: activity found")
                    launchSdkSync(activity, call, result, remoteMethodBridge)
                } else {
                    Log.v(TAG, "onLaunchSDK: activity not found")
                    launchSdkAsync(call, result, remoteMethodBridge)
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Registers this instance as a method call handler on the given {@code messenger}.
     *
     * <p>Stops any previously started and unstopped calls.
     *
     * <p>This should be cleaned with {@link #stopListening} once the messenger is disposed of.
     */
    @SuppressLint("LogNotTimber")
    fun startListening(messenger: BinaryMessenger) {
        if (methodChannel != null) {
            Log.v(TAG, "startListening: already started")
            return
        }
        methodChannel = MethodChannel(messenger, CHANNEL_NAME)
        methodChannel?.setMethodCallHandler(this)
        Log.v(TAG, "startListening")
    }

    /**
     * Clears this instance from listening to method calls.
     *
     * <p>Does nothing is {@link #startListening} hasn't been called, or if we're already stopped.
     */
    @SuppressLint("LogNotTimber")
    fun stopListening() {
        if (methodChannel == null) {
            Log.v(TAG, "Tried to stop listening when no methodChannel had been initialized.")
            return
        }

        Log.v(TAG, "stopListening")
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }

    fun setActivity(activity: Activity?) {
        Log.v(TAG, "Setting activity: $activity")
        activityHolder.update { activity }
    }

    private fun clear() {
        Log.v(TAG, "clear")
        scope.coroutineContext.cancelChildren()
    }

    /**
     * Launches the SDK with provided [activity].
     */
    private fun launchSdkSync(
        activity: Activity,
        call: MethodCall,
        result: MethodChannel.Result,
        remoteMethodBridge: SNSPluginRemoteMethodBridge
    ) {
        try {
            val sdk = buildSdk(call, remoteMethodBridge, result, activity)

            sdk.launch()
            Log.v(TAG, "SDK launched")

            snsSdk = sdk
        } catch (e: Exception) {
            Log.e(TAG, "Exception occurred during the SDK launch process", e)
            result.error("", e.message, null)
        }
    }

    /**
     * Waits for the Activity to be present and then launches the SDK.
     */
    private fun launchSdkAsync(
        call: MethodCall,
        result: MethodChannel.Result,
        remoteMethodBridge: SNSPluginRemoteMethodBridge
    ) {
        sdkLaunchAsyncJob?.cancel()

        sdkLaunchAsyncJob = scope.launch(
            CoroutineExceptionHandler { _, throwable ->
                Log.e(TAG, "Exception occurred during the SDK launch process", throwable)
                result.error("", throwable.message, null)
            }
        ) {
            Log.v(TAG, "Waiting for activity")

            val activity = withTimeoutOrNull(2.seconds) {
                activityHolder.filterNotNull().first()
            } ?: throw TimeoutException("Failed to get activity within 2 seconds")

            Log.v(TAG, "Activity found")

            val sdk = buildSdk(call, remoteMethodBridge, result, activity)

            sdk.launch()
            Log.v(TAG, "SDK launched")

            snsSdk = sdk
        }
    }

    private fun buildSdk(
        call: MethodCall,
        remoteMethodBridge: SNSPluginRemoteMethodBridge,
        result: MethodChannel.Result,
        activity: Activity
    ): SNSMobileSDK.SDK {
        val apiUrl = call.argument("apiUrl") ?: ""
        val accessToken = call.argument("accessToken") ?: ""
        val languageCode = call.argument("languageCode") ?: ""
        val appConf = call.argument("applicantConf") as? Map<String, String>
        val settings = call.argument("settings") as? Map<String, String>
        val theme = call.argument("theme") as? Map<String, Any>

        val strings = call.argument("strings") as? Map<String, String>
        val isAnalyticsEnabled = call.argument("isAnalyticsEnabled") ?: true
        val isDebug = call.argument("isDebug") ?: false
        val modules: MutableList<SNSModule> = mutableListOf(SNSProoface())
        val preferredDocumentDefinitions = call.argument("preferredDocumentDefinitions") as? Map<String, Any>
        val autoCloseOnApprove = call.argument("autoCloseOnApprove") as? Int

        val onTokenExpirationHandler = object : TokenExpirationHandler {
            override fun onTokenExpired(): String? = runBlocking(Dispatchers.Main.immediate) {
                return@runBlocking methodChannel?.invokeMethodBlock("onTokenExpiration") as? String
            }
        }

        val errorHandler: SNSErrorHandler = object : SNSErrorHandler {
            override fun onError(exception: SNSException) {
                Log.w(TAG, "onError", exception)
                remoteMethodBridge.onLog(SNSLogLevel.Error, "onError: $exception")
                mainHandler?.post {
                    methodChannel?.invokeMethod("onError", exception.toMap())!!
                }
            }
        }

        val stateHandler: SNSStateChangedHandler? = if (call.argument("hasOnStatusChanged") as? Boolean == true) {
            object : SNSStateChangedHandler {
                override fun onStateChanged(previousState: SNSSDKState, currentState: SNSSDKState) {
                    remoteMethodBridge.onLog(SNSLogLevel.Debug, "onStateChanged: $currentState")
                    mainHandler?.post {
                        methodChannel?.invokeMethod(
                            "onStatusChanged",
                            listOf(currentState.toStateString(), previousState.toStateString())
                        )!!
                    }
                }
            }
        } else {
            null
        }

        val eventHandler: SNSEventHandler? = if (call.argument("hasOnEvent") as? Boolean == true) {
            object : SNSEventHandler {
                override fun onEvent(event: SNSEvent) {
                    remoteMethodBridge.onLog(SNSLogLevel.Debug, "onEvent: $event")
                    mainHandler?.post {
                        val eventType = event.eventType.capitalize()
                        val params = event.payload
                            ?.mapKeys { if (it.key == "isCanceled") "isCancelled" else it.key }
                            ?.normalizeEventPayload()

                        methodChannel?.invokeMethod(
                            "onEvent", listOf(
                                mapOf(
                                    "eventType" to eventType,
                                    "payload" to params
                                )
                            )
                        )
                    }
                }
            }
        } else {
            null
        }

        val logger = if (call.argument("hasOnLog") as? Boolean == true) {
            FlutterLoggerAdapter(remoteMethodBridge)
        } else {
            null
        }

        val completeHandler: SNSCompleteHandler = object : SNSCompleteHandler {
            override fun onComplete(r: SNSCompletionResult, state: SNSSDKState) {
                remoteMethodBridge.onLog(SNSLogLevel.Debug, "onComplete: r=$r, s=$state")
                result.success(r.toMap(state))
            }
        }

        val builder = SNSMobileSDK.Builder(activity)

        if (apiUrl.isNotEmpty()) builder.withBaseUrl(apiUrl)

        builder.withAccessToken(accessToken, onTokenExpiration = onTokenExpirationHandler)
            .withCompleteHandler(completeHandler)
            .withStateChangedHandler(stateHandler)
            .withEventHandler(eventHandler)
            .withErrorHandler(errorHandler)
            .withConf(SNSInitConfig(appConf?.get("email"), appConf?.get("phone"), strings))
            .withSettings(settings)
            .withModules(modules)
            .withDebug(isDebug)
            .withLogTree(logger)
            .withAnalyticsEnabled(isAnalyticsEnabled)
        theme?.let {
            builder.withMappedTheme(it, SNSCustomizationFileFormat.FLUTTER)
        }

        preferredDocumentDefinitions?.let {
            val docs = it.entries.mapNotNull { entry ->
                (entry.value as? Map<String, Any>)?.let { doc ->
                    entry.key to SNSDocumentDefinition(
                        idDocType = doc["idDocType"] as? String,
                        country = doc["country"] as? String
                    )
                }
            }.toMap()
            builder.withPreferredDocumentDefinitions(docs)
        }

        autoCloseOnApprove?.also {
            builder.withAutoCloseOnApprove(autoCloseOnApprove)
        }

        if (languageCode.isNotEmpty()) {
            builder.withLocale(Locale(languageCode))
        }

        // Upstream 1.42.0 stores supportEmail and never forwards it. Replace the
        // dashboard email item so this app does not offer that account address.
        val supportEmail = call.argument<String>("supportEmail")
        if (!supportEmail.isNullOrBlank()) {
            builder.withSupportItems(
                listOf(
                    SNSSupportItem(
                        title = "Support",
                        subtitle = "",
                        type = SNSSupportItem.Type.Email,
                        value = supportEmail,
                        iconDrawable = null,
                        iconName = null,
                        onClick = null,
                    )
                )
            )
        }

        return builder.build()
    }

    companion object {
        private const val TAG = "${LOG_TAG}Handler"
        private const val CHANNEL_NAME = "sumsub.com/flutter_idensic_mobile_sdk_plugin"
    }
}

private fun Any.normalizeEventPayload(): Any {
    return when (this) {
        is Int -> this
        is Long -> this
        is Float -> this
        is Double -> this
        is Short -> this
        is Byte -> this
        is String -> this
        is Boolean -> this
        is Map<*, *> -> this.entries.associate { it.key.toString() to it.value }.normalizeMap()
        is Collection<*> -> this.normalizeList()
        else -> this.toString()
    }
}

private fun Map<String, Any?>.normalizeMap(): Map<String, Any?> {
    return this.mapValues { (_, value) ->
        when (value) {
            null -> null
            else -> value.normalizeEventPayload()
        }
    }
}

private fun Collection<Any?>.normalizeList(): Collection<Any?> {
    return map { value -> value?.normalizeEventPayload() }
}

fun SNSException.toMap(): Map<String, Any> {
    val type = when (this) {
        is SNSException.Api -> "Api"
        is SNSException.Network -> "Network"
        is SNSException.Unknown -> "Unknown"
    }

    val payload = when (this) {
        is SNSException.Api -> mapOf("code" to code, "description" to description, "correlationId" to correlationId)
        is SNSException.Network -> mapOf("message" to (message ?: ""))
        is SNSException.Unknown -> mapOf("message" to (message ?: ""))
    }

    return mapOf("type" to type, "payload" to payload)
}

fun SNSCompletionResult.toMap(state: SNSSDKState): Map<String, Any?> {
    val success = this is SNSCompletionResult.SuccessTermination
    var errorType: String? = null
    var errorMsg: String? = null
    if (state is SNSSDKState.Failed) {
        errorType = when (state) {
            is SNSSDKState.Failed.ApplicantNotFound -> "ApplicantNotFound"
            is SNSSDKState.Failed.ApplicantMisconfigured -> "ApplicantMisconfigured"
            is SNSSDKState.Failed.InitialLoadingFailed -> "InitialLoadingFailed"
            is SNSSDKState.Failed.InvalidParameters -> "InvalidParameters"
            is SNSSDKState.Failed.NetworkError -> "NetworkError"
            is SNSSDKState.Failed.Unauthorized -> "Unauthorized"
            else -> "Unknown"
        }

        errorMsg = state.message
        if (state.exception?.message != null) {
            errorMsg += ". ${state.exception?.message}"
        }
    }

    return mapOf(
        "success" to success,
        "status" to state.toStateString(),
        "errorType" to errorType,
        "errorMsg" to errorMsg,
    )
}

fun SNSSDKState.toStateString(): String {
    return when (this) {
        is SNSSDKState.Approved -> "Approved"
        is SNSSDKState.Failed -> "Failed"
        is SNSSDKState.FinallyRejected -> "FinallyRejected"
        is SNSSDKState.Incomplete -> "Incomplete"
        is SNSSDKState.Initial -> "Initial"
        is SNSSDKState.Pending -> "Pending"
        is SNSSDKState.Ready -> "Ready"
        is SNSSDKState.TemporarilyDeclined -> "TemporarilyDeclined"
        else -> "<unknown>"
    }
}
