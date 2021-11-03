import 'package:shared_preferences/shared_preferences.dart';

const String connectedDeviceKey = "connectedDeviceKey";
const String connectedDeviceName = "connectedDeviceName";
const String isFirmwareKey = "isFirmwareKey";

class SharedPrefUtils {


  static Future<bool> existsConnectedDeviceID() async{
    SharedPreferences sp = await getSharedPreferences();
    return sp.containsKey(connectedDeviceKey);
  }

  static Future<String?> getConnectedDeviceID() async{
    return getString(connectedDeviceKey);
  }

  static setConnectedDeviceID(String id) {
    return setString(connectedDeviceKey, id);
  }

  static Future<String?> getConnectedDeviceName() async{
    return  getString(connectedDeviceName);
  }

  static  setConnectedDeviceName(String name) {
    return setString(connectedDeviceName, name);
  }

  static setIsFirmware(bool isFirmware) {
    return setBool(isFirmwareKey, isFirmware);
  }

  static Future<bool?> isFirmware() async{
    bool? isFirmware = await getBool(isFirmwareKey);
    return isFirmware;
  }

  static clearConnectedDeviceID() {
    return remove(connectedDeviceKey);
  }

  static clearConnectedDeviceName() {
    return remove(connectedDeviceName);
  }

  static Future<String?> getString(String key) async {
    SharedPreferences sp = await getSharedPreferences();
    return sp.getString(key);
  }

 static  setString(String key, String value) async {
    SharedPreferences sp = await getSharedPreferences();
    return sp.setString(key, value);
  }

  static Future<bool?> getBool(String key) async{
    SharedPreferences sp = await getSharedPreferences();
    return sp.getBool(key);
  }

  static setBool(String key, bool value) async{
    SharedPreferences sp = await getSharedPreferences();
    return sp.setBool(key, value);
  }

 static remove(String key) async{
    SharedPreferences sp = await getSharedPreferences();
    return sp.remove(key);
  }
  static Future<SharedPreferences> getSharedPreferences() async{
    return await SharedPreferences.getInstance();
  }
}
