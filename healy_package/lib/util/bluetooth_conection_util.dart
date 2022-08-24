import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_plugin/flutter_plugin.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';
import 'package:healy_watch_sdk/util/shared_pref.dart';
import 'package:path_provider/path_provider.dart';
import 'ble_sdk.dart';

class BluetoothConnectionUtil {
  static const loggerName = 'HealyWatchSDK - BluetoothConnectionUtil';
  final _stateStreamController =
      StreamController<List<DiscoveredDevice>>.broadcast();

  final _devices = <DiscoveredDevice>[];
  StreamSubscription? _subscription;

  /// Connection class supplied by Flutter BLE package
  late FlutterReactiveBle bleManager;
  StreamSubscription<ConnectionStateUpdate>? _connection;

  /// Actual device that is currently connected

  /// Characteristic for writing data
  QualifiedCharacteristic? _characteristicData;

  /// Characteristic for reading data

  /// current device connection state data
  BluetoothConnectionState lastState = BluetoothConnectionState.bluetoothOff;

  /// device connection state stream
  final connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();

  /// Stream that returns devices while scanning for watch

  //late Timer _autoConnectionTimer;
  // late StreamSubscription _deviceConnectionSubscription;
  bool isNeedReconnect = true;
  bool isFirmwareUpdating = false;

  static BluetoothConnectionUtil? _singleton;

  get isSetup => null;

  DeviceConnectionState _deviceConnectionState =
      DeviceConnectionState.disconnected;

  static BluetoothConnectionUtil? instance() {
    if (_singleton == null) {
      _singleton = BluetoothConnectionUtil();
      _singleton!.init();
    }
    return _singleton;
  }

  BluetoothConnectionUtil() {
    bleManager = FlutterReactiveBle();
    bleManager.statusStream.listen((event) async {
      log("[$BluetoothConnectionUtil] $event");
      if (event == BleStatus.poweredOff) {
        //disconnect();
      } else if (event == BleStatus.ready) {
        bool? isFirmware = await SharedPrefUtils.isFirmware();
        log("[$BluetoothConnectionUtil] isFirmware $isFirmware");
        if (isFirmware != null && isFirmware) {
          final Directory directory = await getApplicationDocumentsDirectory();
          final String rootPath = directory.path;
          HealyWatchSDKImplementation.instance.searchDeviceAndUpdateFirmware(
              rootPath, StreamController<double>());
        } else {
          if (isNeedReconnect) {
            await toConnectExistId();
          }
        }
      }
    });

    bleManager.connectedDeviceStream.listen((conectionState) =>
        _deviceConnectionState = conectionState.connectionState);
  }

  toConnectExistId() async {
    log(
      'toConnectExistId',
      name: loggerName,
      time: DateTime.now(),
    );
    // SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    HealyDevice? device = await SharedPrefUtils.getConnectedDevice();
    if (device != null) {
      await reconnectDevice(device);
    }
  }

  Future<void> init() async {
    log(
      'init',
      name: loggerName,
      time: DateTime.now(),
    );
    return;
  }

  /// Returns a stream of the current [BluetoothConnectionState] of the paired device
  /// Will only stop after unpairing the device, this is helper functionality to overcome small disconnects with a paired device
  // Stream<BluetoothConnectionState> connectionStateStream() async* {
  //   /// debounce stream to "buffer" when multiple events are rapidly fired after eachother
  //   yield* connectionStateController.stream
  //       .debounceTime(const Duration(milliseconds: 300));
  // }

  /// change the current [state] of the paired device
  void setConnectionState(BluetoothConnectionState state) {
    log(
      'setConnectionState $state',
      name: loggerName,
      time: DateTime.now(),
    );
    if (state != lastState) {
      lastState = state;
      connectionStateController.add(state);
    }
  }

  /// run a check for the current connection state (check if bluetooth is on, device id is known etc.), set the current stream state accordingly and return the given state
  // Future<BluetoothConnectionState> checkCurrentState() async {
  //   BluetoothConnectionState state;
  //   final bluetooth = await getBluetoothState();
  //   log("getBluetoothState()$bluetooth");
  //   if (bluetooth != BluetoothState.POWERED_ON) {
  //     state = BluetoothConnectionState.bluetoothOff;
  //   } else if (!await existsConnectedDeviceID()) {
  //     state = BluetoothConnectionState.hasNoDevice;
  //   } else if (bluetoothDevice == null ||
  //       !(await bluetoothDevice.isConnected())) {
  //     state = BluetoothConnectionState.knownDeviceNotConnected;
  //   } else if (await bluetoothDevice.isConnected()) {
  //     state = BluetoothConnectionState.connected;
  //   }
  //
  //   if (state != null) {
  //     setConnectionState(state);
  //   }
  //   return lastState;
  // }

  /// return a stream of the current [BluetoothState], supply [emitCurrentValue] to also get current state when listening
  // Stream<BluetoothState> listenBluetoothState({bool emitCurrentValue = true}) =>
  //     bleManager.observeBluetoothState(emitCurrentValue: emitCurrentValue);

  /// scans for nearby bluetooth devices [Peripheral] containing the [filterForName] default is "healy watch"
  /// emits a [List<Peripheral>] of all devices that are found so far on each event
  /// stream has to be canceled by calling [stopScan]
  Stream<List<DiscoveredDevice>> startScan(
    String? filterForName,
    List<Uuid> serviceIds,
  ) {
    log(
      'startScan with filter: $filterForName and serviceIds: ${serviceIds.toString()}',
      name: loggerName,
      time: DateTime.now(),
    );
    _devices.clear();
    _subscription?.cancel();
    _subscription = bleManager
        .scanForDevices(withServices: serviceIds)
        .where((event) => filterForName == null
            ? true
            : event.name.toLowerCase().contains(filterForName))
        .listen((device) {
      log(
        'startScan found device: ${device.id}',
        name: loggerName,
        time: DateTime.now(),
      );
      final knownDeviceIndex = _devices.indexWhere((d) => d.id == device.id);
      if (knownDeviceIndex >= 0) {
        _devices[knownDeviceIndex] = device;
      } else {
        _devices.add(device);
      }
      _pushState();
    }, onError: (Object e) {
      log(
        'startScan fails with error: $e',
        name: loggerName,
        time: DateTime.now(),
      );
    });
    _pushState();
    return _stateStreamController.stream;
  }

  void _pushState() {
    _stateStreamController.add(_devices);
  }

  Future<void> stopScan() async {
    log(
      'stopScan',
      name: loggerName,
      time: DateTime.now(),
    );
    await _subscription?.cancel();
    _subscription = null;
    _pushState();
  }

  /// one of the main functions of this class
  /// handles the whole reconnection process when a device has been paired before
  /// takes [autoReconnect] if the connection should always be rebuild when lost, e.g. device is too far away
  /// this function also set the correct [BluetoothConnectionState] displayed by [connectionStateStream]
  // Future<Peripheral> reconnectPairedDevice({bool autoReconnect = true}) async {
  //   if (!await existsConnectedDeviceID()) {
  //     return null;
  //   }
  //
  //   final connected = await isConnected();
  //   if (connected) {
  //     setConnectionState(BluetoothConnectionState.connected);
  //     return bluetoothDevice;
  //   }
  //
  //   final bluetootState = await getBluetoothState();
  //   if (bluetootState == BluetoothState.POWERED_OFF) {
  //     setConnectionState(BluetoothConnectionState.bluetoothOff);
  //     return null;
  //   }
  //
  //   if (!isFirmwareUpdating && !_isPairing) {
  //     _isPairing = true;
  //     setConnectionState(BluetoothConnectionState.tryingToConnect);
  //
  //     try {
  //       if (Platform.isAndroid) {
  //         // Wins prize for shittiest workaround of the month
  //         // Works according to https://stackoverflow.com/questions/43476369/android-save-ble-device-to-reconnect-after-app-close/43482099#43482099
  //         bleManager.startPeripheralScan();
  //         await Future.delayed(const Duration(seconds: 1),
  //             () => bleManager.stopPeripheralScan());
  //       }
  //
  //       final peripheralId = await getConnectedDeviceID();
  //       final Peripheral device =
  //           await _getConnectedDeviceByIdentifier(peripheralId);
  //
  //       log("pairDevice: ${device?.name}");
  //       await pairDevice(device, autoReconnect: autoReconnect);
  //
  //       return device;
  //     } on BleError catch (e) {
  //       await _handleBleErrorCode(e.errorCode.value);
  //       log("reconnectPairedDevice BleError: $e");
  //       return bluetoothDevice;
  //     } catch (e) {
  //       log("reconnectPairedDevice error: $e");
  //       setConnectionState(BluetoothConnectionState.error);
  //       return null;
  //     } finally {
  //       _isPairing = false;
  //     }
  //   } else {
  //     return null;
  //   }
  // }

  // we might have to use a workaround on android where we actually have to scan again for the device we want to connect to
  // first let's see if it works well enough without, since this approach introduces a lot of possible new error sources
  // Future<Peripheral> _scanForDeviceWithId(String id) async {
  //   try {
  //     final ScanResult result = await bleManager
  //         .startPeripheralScan()
  //         .where((ScanResult result) =>
  //             result?.peripheral?.name != null &&
  //             result.peripheral.name
  //                 .toLowerCase()
  //                 .contains(HealyWatchSDKImplementation.filterName) &&
  //             result.peripheral.identifier == id)
  //         .first;
  //     stopScan();
  //     return result.peripheral;
  //   } on Exception catch (e) {
  //     log(e.toString());
  //     stopScan();
  //     return null;
  //   }
  // }

  /// handle connection error code
  // Future<void> _handleBleErrorCode(int code) async {
  //   switch (code) {
  //     case BleErrorCode.operationCancelled:
  //       setConnectionState(BluetoothConnectionState.error);
  //       break;
  //     case BleErrorCode.unknownError:
  //     case BleErrorCode.bluetoothManagerDestroyed:
  //     case BleErrorCode.operationTimedOut:
  //     case BleErrorCode.operationStartFailed:
  //     case BleErrorCode.invalidIdentifiers:
  //     case BleErrorCode.bluetoothUnsupported:
  //       setConnectionState(BluetoothConnectionState.error);
  //       break;
  //
  //     case BleErrorCode.bluetoothUnauthorized:
  //     case BleErrorCode.bluetoothPoweredOff:
  //     case BleErrorCode.bluetoothInUnknownState:
  //     case BleErrorCode.bluetoothResetting:
  //     case BleErrorCode.bluetoothStateChangeFailed:
  //       setConnectionState(BluetoothConnectionState.bluetoothOff);
  //       break;
  //     case BleErrorCode.deviceConnectionFailed:
  //     case BleErrorCode.deviceDisconnected:
  //     case BleErrorCode.deviceNotFound:
  //     case BleErrorCode.deviceRSSIReadFailed:
  //     case BleErrorCode.deviceNotConnected:
  //     case BleErrorCode.deviceMTUChangeFailed:
  //       setConnectionState(BluetoothConnectionState.knownDeviceNotConnected);
  //       break;
  //     case BleErrorCode.deviceAlreadyConnected:
  //       setConnectionState(BluetoothConnectionState.connected);
  //       break;
  //     default:
  //       setConnectionState(BluetoothConnectionState.error);
  //       break;
  //   }
  // }
  //
  // Future<void> _startAutoConnectTimer(Peripheral device) async {
  //   if (_autoConnectionTimer == null || !_autoConnectionTimer.isActive) {
  //     await _clearConnectionArtifacts();
  //     _autoConnectionTimer =
  //         Timer.periodic(const Duration(seconds: 10), (timer) async {
  //       if (!(await isConnected())) {
  //         log("attempting to reconnect ble device: ${device.name}");
  //         reconnectPairedDevice();
  //       }
  //     });
  //   }
  // }
  //
  // /// pair a supplied [device] and initialize all characteristics
  // Future<void> pairDevice(Peripheral device,
  //     {bool autoReconnect = true}) async {
  //   setConnectionState(BluetoothConnectionState.tryingToConnect);
  //   if (!await isConnected()) {
  //     try {
  //       if (!await device.isConnected()) {
  //         await device.connect(refreshGatt: true);
  //       }
  //
  //       bluetoothDevice = device;
  //       await _initCharacteristic(device);
  //       await setConnectedDeviceID(device.identifier);
  //       setConnectionState(BluetoothConnectionState.connected);
  //       // observe connection after successful setup
  //       _startDeviceConnectionObserver(device, autoReconnect);
  //     } on Exception catch (e) {
  //       log(e.toString());
  //       rethrow;
  //     }
  //   }
  // }
  //
  // Future<void> _initCharacteristic(Peripheral device) async {
  //   await device.discoverAllServicesAndCharacteristics();
  //
  //   final List<Service> services = await device.services();
  //   for (final Service service in services) {
  //     for (final Characteristic char in await service.characteristics()) {
  //       if (char.uuid == HealyWatchSDKImplementation.notifyCharacteristic) {
  //         _characteristicNotify = char;
  //       }
  //       if (char.uuid == HealyWatchSDKImplementation.dataCharacteristic) {
  //         _characteristicData = char;
  //       }
  //     }
  //   }
  //   if (_characteristicData != null && Platform.isAndroid) {
  //     // _characteristicData
  //     //     .write(Uint8List.fromList(BleSdk.disableANCS()), false)
  //     //     .whenComplete(() {
  //     //   await device.requestMtu(512);
  //     // });
  //     // await device.requestMtu(512);
  //   }
  //   _characteristicNotify.monitor().listen((event) {
  //     final monitorString = BleSdk.hex2String(event).length > 64
  //         ? "${BleSdk.hex2String(event).substring(0, 64)}..."
  //         : BleSdk.hex2String(event);
  //     log(monitorString);
  //   });
  // }
  //
  // /// completely unpair the current device and remove all residual artifacts
  // Future<void> unpair() async {
  //   await clearConnectedDeviceID();
  //
  //   await _clearConnectionArtifacts();
  //
  //   await _deviceConnectionSubscription?.cancel();
  //   _deviceConnectionSubscription == null;
  //   bluetoothDevice = null;
  //
  //   setConnectionState(BluetoothConnectionState.hasNoDevice);
  // }

  /// clears artefacts from an existing connection
  /// e.g. for safe disconnection
  /// !! DOES NOT UNPAIR THE DEVICE
  // Future<void> _clearConnectionArtifacts() async {
  //   _characteristicData = null;
  //   _characteristicNotify = null;
  //   bluetoothDevice = null;
  // }

  /// returns a [bool] whether the current device is correctly connected
  bool isConnected() {
    return isConnect;
  }

  // void _startDeviceConnectionObserver(Peripheral device, bool autoConnect) {
  //   _deviceConnectionSubscription ??=
  //       device.observeConnectionState().listen((event) {
  //     log("observeConnectionState: $event");
  //     // Handle auto connection timer
  //     if (autoConnect) {
  //       if (event == PeripheralConnectionState.disconnected) {
  //         _startAutoConnectTimer(device);
  //       } else if (event == PeripheralConnectionState.connected) {
  //         _autoConnectionTimer?.cancel();
  //         _autoConnectionTimer = null;
  //       }
  //     }
  //     // handle dispatching correct state
  //     switch (event) {
  //       case PeripheralConnectionState.disconnected:
  //       case PeripheralConnectionState.disconnecting:
  //         connectionStateController
  //             .add(BluetoothConnectionState.knownDeviceNotConnected);
  //         break;
  //
  //       case PeripheralConnectionState.connected:
  //       case PeripheralConnectionState.connecting:
  //         connectionStateController.add(BluetoothConnectionState.connected);
  //         break;
  //     }
  //   });
  // }
  //
  // Future<Peripheral> _getConnectedDeviceByIdentifier(String identifier) async {
  //   final List<Peripheral> connectedDeviceList = [];
  //   connectedDeviceList
  //       .addAll((await bleManager.knownPeripherals([identifier])) ?? []);
  //
  //   final connectedDevice = connectedDeviceList.firstWhere(
  //       (element) => element.identifier == identifier,
  //       orElse: () => null);
  //
  //   if (connectedDevice != null) {
  //     return connectedDevice;
  //   } else {
  //     return bleManager.createUnsafePeripheral(identifier);
  //   }
  // }

  /// write [data] to the _characteristicData of the currently paired device
  Future<void> writeData(
    Uint8List data, {
    String? transactionId,
  }) async {
    //await reconnectPairedDevice();
    //if (await isConnected()) {
    return bleManager.writeCharacteristicWithoutResponse(
      _characteristicData!,
      value: data,
    );

    // }
  }

  Stream<List<int>> monitorNotify() {
    return streamController.stream;
  }

  HealyDevice? device;

  Future<void> connectWithDevice(
    HealyDevice device, {
    bool autoReconnect = true,
  }) async {
    log(
      'connectWithDevice ${device.id}',
      name: loggerName,
      time: DateTime.now(),
    );
    isNeedReconnect = autoReconnect;
    connect(
      HealyDevice(
        id: device.id,
        name: device.name,
      ),
    );
  }

  Future<void> connect(HealyDevice? device) async {
    log(
      'connect to device: $device',
      name: loggerName,
      time: DateTime.now(),
    );

    if (device == null) {
      return;
    }

    if (_deviceConnectionState == DeviceConnectionState.connecting ||
        _deviceConnectionState == DeviceConnectionState.connected) {
      log(
        'already try to connect to device: $device',
        name: loggerName,
        time: DateTime.now(),
      );
      return;
    }

    await Future.delayed(Duration(seconds: 1));

    if (_connection != null) {
      log(
        'already connecting to device: $device',
        name: loggerName,
        time: DateTime.now(),
      );
      return;
    }

    final timeout = const Duration(
      seconds: 30,
    );

    final stream = bleManager.connectToDevice(
      id: device.id,
      connectionTimeout: timeout,
    );

    log(
      'connect set connection subscription',
      name: loggerName,
      time: DateTime.now(),
    );

    _connection = stream.listen((update) async {
      _deviceConnectionState = update.connectionState;
      log(
        'connect connection state for device $device : ${update.connectionState}',
        name: loggerName,
        time: DateTime.now(),
      );
      // _deviceConnectionController.add(update);
      if (update.connectionState == DeviceConnectionState.connected) {
        log(
          'connect connected device $device successfully',
          name: loggerName,
          time: DateTime.now(),
        );

        HealyWatchSDKImplementation.instance
            .startCheckResUpdate(StreamController());

        enableNotification(device);
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        log(
          'connect connected device $device failure',
          name: loggerName,
          time: DateTime.now(),
        );

        isConnect = false;
        this.device = null;

        await streamSubscription?.cancel();
        streamSubscription = null;

        if (isNeedReconnect) {
          await reconnectDevice(device);
        }
      }
    }, onError: (Object e) {
      log(
        'connect connecting to device $device resulted in error $e',
        name: loggerName,
        time: DateTime.now(),
      );
    });
  }

  final StreamController<List<int>> streamController =
      StreamController.broadcast();
  StreamSubscription? streamSubscription;
  bool isConnect = false;

  Future<void> enableNotification(HealyDevice device) async {
    log(
      'enableNotification for device ${device.id}',
      name: loggerName,
      time: DateTime.now(),
    );
    //ios端的是短uuid。android端可以是长uuid
    QualifiedCharacteristic _characteristicNotify = QualifiedCharacteristic(
      characteristicId: Uuid.parse("fff7"),
      serviceId: Uuid.parse("fff0"),
      deviceId: device.id,
    );

    _characteristicData = QualifiedCharacteristic(
      characteristicId: Uuid.parse("fff6"),
      serviceId: Uuid.parse("fff0"),
      deviceId: device.id,
    );

    await streamSubscription?.cancel();
    final stream = bleManager.subscribeToCharacteristic(_characteristicNotify);

    streamSubscription = stream.listen((event) {
      log("[$BluetoothConnectionUtil] notifyData ${BleSdk.hex2String(event)}");
      streamController.add(event);
    }, onError: (Object error) {
      log(
        'enableNotification for device ${device.id} error occours $error',
        name: loggerName,
        time: DateTime.now(),
      );
    });
    if (Platform.isAndroid) {
      writeData(Uint8List.fromList(BleSdk.disableANCS()));
    } else {
      writeData(Uint8List.fromList(BleSdk.enableANCS()));
    }
    isConnect = true;
    isNeedReconnect = true;
    this.device = device;
    SharedPrefUtils.setConnectedDevice(device);
  }

  Future<void> disconnect() async {
    try {
      log(
        'disconnect from device $device',
        name: loggerName,
        time: DateTime.now(),
      );

      if (Platform.isIOS) {
        writeData(Uint8List.fromList(BleSdk.disableANCS()));
      }

      SharedPrefUtils.clearConnectedDevice();

      isConnect = false;
      isNeedReconnect = false;
      this.device = null;

      await streamSubscription?.cancel();
      streamSubscription = null;

      await Future.delayed(Duration(seconds: 1));
      await _connection?.cancel();
      _connection = null;

      //  await SharedPrefUtils.clearConnectedDevice();
    } on Exception catch (e, _) {
      log(
        'disconnect error while disconnect from device $device  error $e',
        name: loggerName,
        time: DateTime.now(),
      );
    } finally {
      // Since [_connection] subscription is terminated, the "disconnected" state cannot be received and propagated

    }
  }

  /// read data as [Uint8List] from the _characteristicNotify of the currently paired device
  // Stream<Uint8List> monitorNotify({String transactionId}) async* {
  //   await reconnectPairedDevice();
  //   if (await isConnected()) {
  //     yield* _characteristicNotify.monitor(transactionId: transactionId);
  //   }
  // }
  //
  // /// async returns current [BluetoothState]
  BleStatus getBluetoothState() {
    return bleManager.status;
  }

  Stream<DeviceConnectionState> connectionStateStream() {
    return bleManager.connectedDeviceStream
        .map((event) => event.connectionState);
  }

  Future<DeviceConnectionState> connectionState() {
    return Future.value(_deviceConnectionState);
  }

  /// returns [Stream<bool>] of the current setup state of the connection
  Stream<bool> isSetupDone() async* {
    yield* isSetup.stream;
  }

  Future<HealyDevice?> reconnect({bool autoReconnect = true}) async {
    log(
      'reconnect with autoReconnect $autoReconnect',
      name: loggerName,
      time: DateTime.now(),
    );
    HealyDevice? device = await SharedPrefUtils.getConnectedDevice();
    return reconnectDevice(
      device,
      autoReconnect: autoReconnect,
    );
  }

  Future<HealyDevice?> reconnectDevice(
    HealyDevice? device, {
    bool autoReconnect = true,
  }) async {
    log(
      'reconnectDevice to device $device with autoReconnect $autoReconnect',
      name: loggerName,
      time: DateTime.now(),
    );
    await _connection?.cancel();
    _connection = null;
    //await Future.delayed(Duration(seconds: 2));
    if (bleManager.status == BleStatus.poweredOff ||
        isFirmwareUpdating ||
        device == null) {
      return null;
    }
    await stopScan();
    bool isBind = await FlutterPlugin.isBind(device.id);
    log("[$BluetoothConnectionUtil] $isBind");
    if (isBind) {
      await connect(device);
      return device;
    }

    StreamSubscription<List<DiscoveredDevice>> streamSubscription =
        startScan(HealyWatchSDKImplementation.filterName, List.empty())
            .listen((event) {});
    streamSubscription.onData((data) async {
      data.forEach((element) async {
        if (element.id.toString() == device.id) {
          log("[$BluetoothConnectionUtil] start connect");
          streamSubscription.cancel();
          stopScan();
          await connect(device);
        }
      });
    });

    return device;

    // this.connectedDevice=value;connect(value.id);
    // return value;
  }
}

enum BluetoothConnectionState {
  bluetoothOff,
  hasNoDevice,
  knownDeviceNotConnected,
  tryingToConnect,
  connected,
  error
}
