import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'reactive_state.dart';

class BleDeviceConnector extends ReactiveState<ConnectionStateUpdate> {
  BleDeviceConnector({
    required FlutterReactiveBle ble,
    required Function(String message) logMessage,
  })  : _ble = ble,
        _logMessage = logMessage;

  final FlutterReactiveBle _ble;
  final void Function(String message) _logMessage;

  @override
  Stream<ConnectionStateUpdate> get state => _deviceConnectionController.stream;

  final _deviceConnectionController = StreamController<ConnectionStateUpdate>();

  // ignore: cancel_subscriptions
  late StreamSubscription<ConnectionStateUpdate> _connection;

  Future<void> connect(String deviceId) async {
    _logMessage('Start connecting to $deviceId');
    _connection = _ble
        .connectToDevice(
            id: deviceId,
            //autoConnectFLag
            connectionTimeout: const Duration(seconds: 30))
        .listen(
      (update) {
        _logMessage(
            'ConnectionState for device $deviceId : ${update.connectionState}');
        _deviceConnectionController.add(update);
        debugPrint("enableNotification${update.connectionState}");
        if (update.connectionState == DeviceConnectionState.connected) {
          enableNotification(deviceId);
        }
      },
      onError: (Object e) =>
          _logMessage('Connecting to device $deviceId resulted in error $e'),
    );
  }

  Future<void> enableNotification(String deviceId) async {
    _logMessage('enableNotification');
    debugPrint("enableNotification");
    final characteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse("0000fff7-0000-1000-8000-00805f9b34fb"),
        serviceId: Uuid.parse("0000fff0-0000-1000-8000-00805f9b34fb"),
        deviceId: deviceId);
    _ble.subscribeToCharacteristic(characteristic).listen((event) {
      debugPrint("notifyData $event");
    });
  }

  void writeData(String deviceId) {
    _logMessage('writeData');
    debugPrint("writeData $deviceId");
    final characteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse("0000fff6-0000-1000-8000-00805f9b34fb"),
        serviceId: Uuid.parse("0000fff0-0000-1000-8000-00805f9b34fb"),
        deviceId: deviceId);
    _ble.writeCharacteristicWithoutResponse(characteristic,
        value: getDeviceTime());
  }

  List<int> getDeviceTime() {
    final List<int> value = generateInitValue();
    value[0] = 0x41;
    crcValue(value);
    return value;
  }

  List<int> generateInitValue() {
    return generateValue(16);
  }

  List<int> generateValue(int size) {
    final List<int> value = List<int>.generate(size, (int index) {
      return 0;
    });
    return value;
  }

  /// crc validation
  static void crcValue(List<int> list) {
    int crcValue = 0;
    for (final int value in list) {
      crcValue += value;
    }
    list[15] = crcValue & 0xff;
  }

  Future<void> disconnect(String deviceId) async {
    try {
      _logMessage('disconnecting to device: $deviceId');
      await _connection.cancel();
    } on Exception catch (e, _) {
      _logMessage("Error disconnecting from a device: $e");
    } finally {
      // Since [_connection] subscription is terminated, the "disconnected" state cannot be received and propagated
      _deviceConnectionController.add(
        ConnectionStateUpdate(
          deviceId: deviceId,
          connectionState: DeviceConnectionState.disconnected,
          failure: null,
        ),
      );
    }
  }

  Future<void> dispose() async {
    await _deviceConnectionController.close();
  }
}
