import 'package:shared_preferences/shared_preferences.dart';

const String connectedDeviceKey = "connectedDeviceKey";

Future<bool> existsConnectedDeviceID() async {
  final sp = await SharedPreferences.getInstance();
  return sp.containsKey(connectedDeviceKey);
}

Future<String?> getConnectedDeviceID() async {
  final sp = await SharedPreferences.getInstance();
  return sp.getString(connectedDeviceKey);
}

Future<bool> setConnectedDeviceID(String id) async {
  final sp = await SharedPreferences.getInstance();
  return sp.setString(connectedDeviceKey, id);
}

Future<bool> clearConnectedDeviceID() async {
  final sp = await SharedPreferences.getInstance();
  return sp.remove(connectedDeviceKey);
}
