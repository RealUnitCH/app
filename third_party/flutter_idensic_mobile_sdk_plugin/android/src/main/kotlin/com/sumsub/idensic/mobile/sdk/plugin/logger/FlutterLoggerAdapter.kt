package com.sumsub.idensic.mobile.sdk.plugin.logger

import com.sumsub.idensic.mobile.sdk.plugin.bridge.SNSPluginRemoteMethodBridge
import com.sumsub.log.logger.Logger

internal class FlutterLoggerAdapter(
    private val methodBridge: SNSPluginRemoteMethodBridge,
) : Logger {

    override fun d(tag: String, message: String, throwable: Throwable?) {
        log(SNSLogLevel.Debug, message)
    }

    override fun e(tag: String, message: String, throwable: Throwable?) {
        log(SNSLogLevel.Error, message)
    }

    override fun i(tag: String, message: String, throwable: Throwable?) {
        log(SNSLogLevel.Info, message)
    }

    override fun v(tag: String, message: String, throwable: Throwable?) {
        log(SNSLogLevel.Verbose, message)
    }

    override fun w(tag: String, message: String, throwable: Throwable?) {
        log(SNSLogLevel.Warning, message)
    }

    private fun log(level: SNSLogLevel, message: String) {
        methodBridge.onLog(level, message)
    }
}
