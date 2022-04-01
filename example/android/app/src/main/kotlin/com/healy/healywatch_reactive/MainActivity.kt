package com.healy.healywatch_reactive

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity: FlutterActivity(),FlutterPlugin, MethodChannel.MethodCallHandler {
    private  val TAG = "MainActivity"
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(binding.binaryMessenger, "pairedDevice")
        channel.setMethodCallHandler( this)
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // deinitalize logic
    }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method.equals("paired")) {
            android.util.Log.i(TAG, "onMethodCall: ")
            result.success("")
        } else {
            result.notImplemented()
        }
    }
}
