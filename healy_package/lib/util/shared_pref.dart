import 'dart:convert';
import 'dart:developer';

import 'package:healy_watch_sdk/model/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String connectedDeviceKey = "connectedDevice";
const String isFirmwareKey = "isFirmwareKey";

class SharedPrefUtils {
  static Future<bool> existsConnectedDeviceID() async {
    SharedPreferences sp = await getSharedPreferences();
    return sp.containsKey(connectedDeviceKey);
  }

  static Future<HealyDevice?> getConnectedDevice() async {
    final jsonStr = await getString(connectedDeviceKey);
    if (jsonStr != null) {
      final map = jsonDecode(jsonStr);
      final device = HealyDevice.fromJson(map);
      log(
        'getConnectedDevice: $jsonStr',
        time: DateTime.now(),
        name: 'SharedPrefUtils',
      );
      return device;
    }
    return null;
  }

  static setConnectedDevice(HealyDevice device) {
    log(
      'setConnectedDevice: $device',
      time: DateTime.now(),
      name: 'SharedPrefUtils',
    );
    return setString(
      connectedDeviceKey,
      jsonEncode(device),
    );
  }

  static setIsFirmware(bool isFirmware) {
    return setBool(isFirmwareKey, isFirmware);
  }

  static Future<bool?> isFirmware() async {
    bool? isFirmware = await getBool(isFirmwareKey);
    return isFirmware;
  }

  static clearConnectedDevice() {
    return remove(connectedDeviceKey);
  }

  static Future<String?> getString(String key) async {
    SharedPreferences sp = await getSharedPreferences();
    return sp.getString(key);
  }

  static setString(String key, String value) async {
    SharedPreferences sp = await getSharedPreferences();
    return sp.setString(key, value);
  }

  static Future<bool?> getBool(String key) async {
    SharedPreferences sp = await getSharedPreferences();
    return sp.getBool(key);
  }

  static setBool(String key, bool value) async {
    SharedPreferences sp = await getSharedPreferences();
    return sp.setBool(key, value);
  }

  static remove(String key) async {
    SharedPreferences sp = await getSharedPreferences();
    return sp.remove(key);
  }

  static Future<SharedPreferences> getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }
}
