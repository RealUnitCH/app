package com.sumsub.idensic.mobile.sdk.plugin.bridge

import android.os.Handler
import android.os.Looper
import com.sumsub.idensic.mobile.sdk.plugin.logger.SNSLogLevel
import io.flutter.plugin.common.MethodChannel

internal class SNSPluginRemoteMethodBridge(
    private val methodChannelProvider: () -> MethodChannel?,
) {

    private val handler = Handler(Looper.getMainLooper())

    fun onLog(level: SNSLogLevel, message: String) {
        invokeOnUi(
            method = "onLog",
            arguments = mapOf(
                "level" to level.remoteLevel,
                "message" to message
            )
        )
    }

    private fun invokeOnUi(
        method: String,
        arguments: Map<String, Any>
    ) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            methodChannelProvider()?.invokeMethod(
                /* method = */ method,
                /* arguments = */ arguments
            )
        } else {
            handler.post {
                methodChannelProvider()?.invokeMethod(
                    /* method = */ method,
                    /* arguments = */ arguments
                )
            }
        }
    }
}
