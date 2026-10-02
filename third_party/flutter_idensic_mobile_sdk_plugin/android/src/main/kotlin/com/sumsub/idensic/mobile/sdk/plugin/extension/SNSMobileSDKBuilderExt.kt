package com.sumsub.idensic.mobile.sdk.plugin.extension

import com.sumsub.log.logger.Logger
import com.sumsub.sns.core.SNSMobileSDK

internal fun SNSMobileSDK.Builder.withLogTree(logTree: Logger?): SNSMobileSDK.Builder {
    return if (logTree != null) {
        withLogTree(logTree)
    } else {
        this
    }
}
