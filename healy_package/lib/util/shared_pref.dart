import 'package:shared_preferences/shared_preferences.dart';

const String connectedDeviceKey = "connectedDeviceKey";
const String connectedDeviceName = "connectedDeviceName";
const String isFirmwareKey = "isFirmwareKey";

class SharedPrefUtils {
  static final SharedPrefUtils _instance = SharedPrefUtils._();

  SharedPrefUtils._() {}
  SharedPreferences? sp;

  static SharedPrefUtils get instance => _instance;

  init() async {
    sp = await SharedPreferences.getInstance();
  }

  bool existsConnectedDeviceID() {
    return sp!.containsKey(connectedDeviceKey);
  }

  String? getConnectedDeviceID() {
    return getString(connectedDeviceKey);
  }

  setConnectedDeviceID(String id) {
    return setString(connectedDeviceKey, id);
  }

  String? getConnectedDeviceName() {
    return getString(connectedDeviceName);
  }

  setConnectedDeviceName(String name) {
    return setString(connectedDeviceName, name);
  }
  setIsFirmware(bool isFirmware) {
    return setBool(isFirmwareKey, isFirmware);
  }
  isFirmware(){
    return getBool(isFirmwareKey);
  }
  clearConnectedDeviceID() {
    return remove(connectedDeviceKey);
  }

  clearConnectedDeviceName() {
    return remove(connectedDeviceName);
  }

  String? getString(String key) {
    return sp!.getString(key);
  }

  setString(String key, String value) {
    return sp!.setString(key, value);
  }

  bool? getBool(String key) {
    return sp!.getBool(key);
  }

  setBool(String key, bool value) {
    return sp!.setBool(key, value);
  }

  remove(String key) {
    return sp!.remove(key);
  }
}
