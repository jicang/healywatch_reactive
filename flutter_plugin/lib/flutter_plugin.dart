import 'dart:async';

import 'package:flutter/services.dart';

class FlutterPlugin {
  static const MethodChannel _channel = MethodChannel('flutter_plugin');

  static Future<dynamic> get platformVersion async {
    var version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<dynamic> isBind(String id) async {
    var isBind = await _channel.invokeMethod('getPaired', {"deviceId": id});
    return isBind;
  }
}
