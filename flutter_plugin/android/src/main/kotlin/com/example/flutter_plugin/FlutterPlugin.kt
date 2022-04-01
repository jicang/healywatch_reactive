package com.example.flutter_plugin

import androidx.annotation.NonNull
import android.bluetooth.BluetoothAdapter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterPlugin */
class FlutterPlugin : FlutterPlugin, MethodCallHandler {
    private  val TAG = "FlutterPlugin"

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "getPlatformVersion") {

            result.success(isBind("ss"))
        } else if (call.method == "getPaired") {
            var deviceId :String= call.argument("deviceId")!!;
            result.success(isBind(deviceId))
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    fun isBind(deviceId: String): Boolean {
        android.util.Log.i(TAG, "isBind: $deviceId")
        var isBind = false;
        var adapter = BluetoothAdapter.getDefaultAdapter()
        var devices = adapter.bondedDevices
        devices.forEach {
            if (it.address == deviceId) isBind = true;
        }
        return isBind;
    }
}
