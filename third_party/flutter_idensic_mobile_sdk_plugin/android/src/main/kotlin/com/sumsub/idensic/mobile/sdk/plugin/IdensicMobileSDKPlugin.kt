package com.sumsub.idensic.mobile.sdk.plugin

import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** IdensicMobileSDKPlugin */
class IdensicMobileSDKPlugin : FlutterPlugin, ActivityAware {

    private val handler: MethodCallHandler = MethodCallHandler()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.v(LOG_TAG, "onAttachedToEngine")
        handler.startListening(binding.binaryMessenger)
        handler.ctx = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.v(LOG_TAG, "onDetachedFromEngine")
        // Note: in current demo impl this does NOT ever happens
        handler.setActivity(null)
        handler.ctx = null
        handler.stopListening()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.v(LOG_TAG, "onAttachedToActivity")
        handler.setActivity(binding.activity)
    }

    override fun onDetachedFromActivity() {
        Log.v(LOG_TAG, "onDetachedFromActivity")
        handler.setActivity(null)
        // we do NOT stop listening because the activity might already be destroyed
        // but the callbacks must be still delivered
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }
}
