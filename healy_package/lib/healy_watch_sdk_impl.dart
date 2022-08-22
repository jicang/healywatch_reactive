import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:healy_watch_sdk/util/shared_pref.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
import 'package:path_provider/path_provider.dart';

import 'bleconst/device_cmd.dart';
import 'healy_watch_sdk.dart';
import 'model/device_version_response.dart';
import 'model/firmware_data.dart';
import 'model/models.dart';
import 'util/ble_sdk.dart';
import 'util/bluetooth_conection_util.dart';
import 'util/resolve_util.dart';
import 'util/resource_update_util.dart';

class HealyWatchSDKImplementation implements HealyWatchSDK {
  static const String filterName = "healy";
  static const String dataService = "0000fff0-0000-1000-8000-00805f9b34fb";
  static const String dataCharacteristic =
      "0000fff6-0000-1000-8000-00805f9b34fb";
  static const String notifyCharacteristic =
      "0000fff7-0000-1000-8000-00805f9b34fb";

  // BluetoothDevice bluetoothDevice;
  List<HealyPPGData> healyPPGDataList = [];
  List<HealyECGData> healyEcgDataList = [];
  List<HealyECGQualityData> qualityPoints = [];
  Map<String, DiscoveredDevice> devices = {};

  late BluetoothConnectionUtil _bluetoothUtil;

  BluetoothConnectionUtil get bluetoothUtil => _bluetoothUtil;

  final scanDevicesController =
      StreamController<List<DiscoveredDevice>>.broadcast();

  // static Future<BluetoothConnectionUtil>  bluetoothUtil;

  static final HealyWatchSDKImplementation _instance =
      HealyWatchSDKImplementation._();
  HealyWatchSDKImplementation._() {
    _bluetoothUtil = BluetoothConnectionUtil.instance()!;
  }

  static HealyWatchSDKImplementation get instance => _instance;

  @override
  Stream<List<DiscoveredDevice>> scanResults({
    String filterForName = HealyWatchSDKImplementation.filterName,
    List<String>? ids,
  }) {
    final minDateTime = DateTime.now().add(const Duration(
      seconds: 2,
    ));
    bluetoothUtil.startScan(
      filterForName,
      [],
    ).listen((event) {
      if (DateTime.now().isAfter(minDateTime)) {
        scanDevicesController.add(event);
      }
    });
    return scanDevicesController.stream;
  }

  @override
  Future<void> cancelScanningDevices() async {
    await bluetoothUtil.stopScan();
  }

  @override
  Future<void> connectDevice(
    HealyDevice device, {
    bool autoReconnect = true,
  }) async {
    await bluetoothUtil.connectWithDevice(
      device,
      autoReconnect: autoReconnect,
    );
  }

  @override
  Future<void> disconnectDevice() async{
    if(Platform.isIOS){
      await disableANCS();
    }
    return bluetoothUtil.disconnect();
  }

  @override
  Future<HealyDevice?> reconnectDevice({bool autoReconnect = true}) async {
    return bluetoothUtil.reconnect(autoReconnect: autoReconnect);
  }

  // // returns wether the watch is PROPERLY connected, meaning the devices are paired and it is possible to call functions on the watch
  @override
  bool isConnected() {
    return bluetoothUtil.isConnected();
  }

  //
  // // returns the connected device synchronously
  // // will return null if the device has not been reinitialized properly even if there is a connected device
  @override
  HealyDevice? getConnectedDevice() {
    return bluetoothUtil.device;
  }

  @override
  Future<DeviceConnectionState> getConnectionState() {
    return bluetoothUtil.connectionState();
  }

  Stream<bool> isSetupDone() async* {
    yield* bluetoothUtil.isSetupDone();
  }

  void onError(dynamic error) {
    log('Error: $error');
  }

  StreamController<HealyBaseModel>? allDataStreamController =
      StreamController<HealyBaseModel>();

  Future _getWatchData(int cmd, StreamController streamController) async {
    final completer = Completer();
    _getDataStream(cmd).listen((event) {
      for (final healyDailyEvaluation in event) {
        if (!streamController.isClosed) {
          streamController.add(healyDailyEvaluation);
        }
      }
    }).onDone(() {
      completer.complete();
    });
    return completer.future;
  }

  @override
  Stream<HealyBaseModel> getAllDataFromWatch() {
    allDataStreamController = StreamController<HealyBaseModel>();

    // fetch dailyEvaluations from watch
    _getWatchData(DeviceCmd.getTotalData, allDataStreamController!)
        .then((_) =>
            _getWatchData(DeviceCmd.getDetailData, allDataStreamController!))
        .then((_) =>
            _getWatchData(DeviceCmd.getSleepData, allDataStreamController!))
        .then((_) => _getWatchData(
            DeviceCmd.getDynamicHeartData, allDataStreamController!))
        .then((_) => _getWatchData(
            DeviceCmd.getStaticHeartData, allDataStreamController!))
        .then((_) => _getWatchData(
            DeviceCmd.getHrvHistoryData, allDataStreamController!))
        .then((_) =>
            _getWatchData(DeviceCmd.getWorkOutData, allDataStreamController!))
        .whenComplete(() => allDataStreamController!.close());

    return allDataStreamController!.stream;
  }

  @override
  Future<bool> deleteAllDailyActivities() async {
    await _writeData(BleSdk.deleteAllTotalData());
    return _filterDeleteValue(DeviceCmd.getTotalData).then((value) => true);
  }

  @override
  Future<bool> deleteAllDynamicHeartRates() async {
    await _writeData(BleSdk.deleteAllDynamicHeartRateData());
    return _filterDeleteValue(DeviceCmd.getDynamicHeartData)
        .then((value) => true);
  }

  @override
  Future<bool> deleteAllWorkoutData() async {
    await _writeData(BleSdk.deleteAllWorkOutData());
    return _filterDeleteValue(DeviceCmd.getWorkOutData).then((value) => true);
  }

  @override
  Future<bool> deleteAllECGData() async {
    await _writeData(BleSdk.deleteAllHRVHistoryData());
    return _filterDeleteValue(DeviceCmd.getHrvHistoryData)
        .then((value) => true);
  }

  @override
  Future<bool> deleteAllSleepData() async {
    await _writeData(BleSdk.deleteAllSleepData());
    return _filterDeleteValue(DeviceCmd.getSleepData).then((value) => true);
  }

  @override
  Future<bool> deleteAllStaticHeartRates() async {
    await _writeData(BleSdk.deleteAllStaticHeartRateData());
    return _filterDeleteValue(DeviceCmd.getStaticHeartData)
        .then((value) => true);
  }

  @override
  Future<bool> deleteDailyEvaluationBlocks() async {
    await _writeData(BleSdk.deleteAllDailyEvaluationBlocks());
    return _filterDeleteValue(DeviceCmd.getDetailData).then((value) => true);
  }

  @override
  Stream<List<HealyDailyEvaluation>> getDailyEvaluationByDay({DateTime? date}) {
    return _getDataStream(DeviceCmd.getTotalData, date: date)
        as Stream<List<HealyDailyEvaluation>>;
  }

  bool _isDataResponseEnd(List<int> value, int cmd) {
    return value[value.length - 2] == cmd && value[value.length - 1] == 0xff;
  }

  @override
  Stream<List<HealyDailyDynamicHeartRate>> getAllDynamicHeartRates(
      {DateTime? date}) {
    final Stream stream =
        _getDataStream(DeviceCmd.getDynamicHeartData, date: date);
    return stream as Stream<List<HealyDailyDynamicHeartRate>>;
  }

  @override
  Stream<List<HealyWorkoutData>> getAllWorkoutData({DateTime? date}) {
    final Stream stream = _getDataStream(DeviceCmd.getWorkOutData, date: date);
    return stream as Stream<List<HealyWorkoutData>>;
  }

  @override
  Stream<List<HealyEcgSuccessData>> getAllHRVData({DateTime? date}) {
    return _getDataStream(DeviceCmd.getHrvHistoryData, date: date)
        as Stream<List<HealyEcgSuccessData>>;
  }

  @override
  Stream<List<HealyDailyEvaluationBlock>> getAllDailyEvaluationBlocks(
      {DateTime? date}) {
    return _getDataStream(DeviceCmd.getDetailData, date: date)
        as Stream<List<HealyDailyEvaluationBlock>>;
  }

  @override
  Stream<List<HealyStaticHeartRate>> getAllStaticHeartRates({DateTime? date}) {
    return _getDataStream(DeviceCmd.getStaticHeartData, date: date)
        as Stream<List<HealyStaticHeartRate>>;
  }

  @override
  Stream<List<HealySleepData>> getAllSleepData({DateTime? date}) {
    return _getDataStream(DeviceCmd.getSleepData, date: date)
        as Stream<List<HealySleepData>>;
  }

  @override
  Future<HealyWorkoutType> getAllWorkoutTypes() async {
    await _writeData(BleSdk.getWorkOutType());
    return _filterValue(DeviceCmd.getWorkoutType)
        .then((value) => ResolveUtil.getWorkOutType(value));
  }

  @override
  Future<DateTime> getDeviceTime() async {
    await _writeData(BleSdk.getDeviceTime());
    return _filterValue(DeviceCmd.getTime)
        .then((value) => ResolveUtil.getDeviceTime(value));
  }

  @override
  Future<int> getBatteryLevel() async {
    await _writeData(BleSdk.getBatteryLevel());
    return _filterValue(DeviceCmd.getBatteryLevel)
        .then((value) => ResolveUtil.getDeviceBattery(value));
  }

  @override
  Future<String> getDeviceAddress() async {
    await _writeData(BleSdk.getMacAddress());
    return _filterValue(DeviceCmd.getAddress)
        .then((value) => ResolveUtil.getDeviceAddress(value));
  }

  @override
  Future<String> getFirmwareVersion() async {
    await _writeData(BleSdk.getFirmwareVersion());
    return _filterValue(DeviceCmd.getVersion)
        .then((value) => ResolveUtil.getDeviceVersion(value));
  }

  @override
  Future<HealyHeartRateMeasurementSettings>
      getHeartRateMessurementSettings() async {
    await _writeData(BleSdk.getAutoHeartZone());
    return _filterValue(DeviceCmd.getAutoHeart)
        .then((value) => ResolveUtil.getAutoHeart(value));
  }

  @override
  Future<HealySedentaryReminderSettings> getSedentaryReminderSettings() async {
    await _writeData(BleSdk.getSedentaryReminder());
    return _filterValue(DeviceCmd.getSedentaryReminder)
        .then((value) => ResolveUtil.getActivityAlarm(value));
  }

  @override
  Future<HealyWatchFaceStyle> getSelectedWatchFaceStyles() async {
    await _writeData(BleSdk.getWatchFaceStyle());
    return _filterValue(DeviceCmd.watchFaceStyle)
        .then((value) => ResolveUtil.getWatchFaceStyle(value));
  }

  @override
  Future<HealyWorkoutType> getSelectedWorkoutTypes() async {
    await _writeData(BleSdk.getWorkOutType());
    return _filterValue(DeviceCmd.watchFaceStyle)
        .then((value) => ResolveUtil.getWorkOutType(value));
  }

  @override
  Future<HealyUserInformation> getUserInformation() async {
    await _writeData(BleSdk.getUserInfo());
    return _filterValue(DeviceCmd.getUserInfo)
        .then((value) => ResolveUtil.getUserInfo(value));
  }

  @override
  Future<HealyWorkoutReminderSettings> getWorkoutReminderSettings() async {
    await _writeData(BleSdk.getWorkOutReminder());
    return _filterValue(DeviceCmd.getWorkoutReminder)
        .then((value) => ResolveUtil.getWorkOutReminder(value));
  }

  @override
  Future<HealySetDeviceTime> setDeviceTime(DateTime deviceTime) async {
    await _writeData(BleSdk.setDeviceTime(deviceTime));
    return _filterValue(DeviceCmd.setTime)
        .then((value) => ResolveUtil.setTimeSuccessFul(value));
  }

  @override
  Future<bool> setHeartRateMeasurementSettings(
      HealyHeartRateMeasurementSettings settings) async {
    await _writeData(BleSdk.setAutoHeartZone(settings));
    return _filterValue(DeviceCmd.setAutoHeart).then((value) => true);
  }

  @override
  Future<bool> setSedentaryReminder(
      HealySedentaryReminderSettings reminderSettings) async {
    await _writeData(BleSdk.setSedentaryReminder(reminderSettings));
    return _filterValue(DeviceCmd.setSedentaryReminder).then((value) => true);
  }

  @override
  Future<bool> setSelectedWorkoutTypes(HealyWorkoutType workoutTypes) async {
    await _writeData(BleSdk.setWorkOutType(workoutTypes.selectedList));
    return _filterValue(DeviceCmd.setWorkoutType).then((value) => true);
  }

  @override
  Future<bool> setUserInformation(HealyUserInformation userInformation) async {
    await _writeData(BleSdk.setUserInfo(userInformation));
    return _filterValue(DeviceCmd.setUserInfo).then((value) => true);
  }

  @override
  Future<bool> setWatchFaceStyle(HealyWatchFaceStyle watchFaceStyle) async {
    await _writeData(BleSdk.setWatchFaceStyle(watchFaceStyle.imageId));
    return _filterValue(DeviceCmd.watchFaceStyle).then((value) => true);
  }

  @override
  Future<bool> setWorkoutReminder(
      HealyWorkoutReminderSettings reminderSettings) async {
    await _writeData(BleSdk.setWorkOutReminder(reminderSettings));
    return _filterValue(DeviceCmd.setWorkoutReminder)
        .then((value) => ResolveUtil.setWorkOutReminder(value));
  }

  @override
  Stream<HealyBaseMeasuremenetData> startEcgMessuring() {
    _writeData(BleSdk.enableEcgPPg());
    return _getEcgMeasuremenetDataStream();
  }

  @override
  Stream<HealyBaseMeasuremenetData> startOnlyPPGMeasuring() {
    _writeData(BleSdk.enableOnlyPPg());
    return _getEcgMeasuremenetDataStream();
  }

  Stream<HealyBaseMeasuremenetData> _getEcgMeasuremenetDataStream() {
    healyEcgDataList.clear();
    healyPPGDataList.clear();
    qualityPoints.clear();
    final StreamController<HealyBaseMeasuremenetData> controller =
        StreamController<HealyBaseMeasuremenetData>();
    final StreamSubscription<List<int>> streamSubscription = bluetoothUtil
        .monitorNotify()
        .where((values) => _ecgMeasuringData(values))
        .listen((event) {});
    streamSubscription.onData((value) {
      HealyBaseMeasuremenetData? healyBaseMeasuremenetData;
      switch (value[0]) {
        case DeviceCmd.enableEcgPpg:
          healyBaseMeasuremenetData = HealyEnterEcgData(
            ecgResultCode: EnterEcgResultCode.values[value[1]],
          );
          break;
        case DeviceCmd.ecgData:
          healyBaseMeasuremenetData = ResolveUtil.ecgMeasureData(value);
          healyEcgDataList.add(healyBaseMeasuremenetData as HealyECGData);
          break;
        case DeviceCmd.ppgData:
          healyBaseMeasuremenetData = ResolveUtil.ppgMeasureData(value);
          healyPPGDataList.add(healyBaseMeasuremenetData as HealyPPGData);
          break;
        case DeviceCmd.ecgQuality:
          healyBaseMeasuremenetData = ResolveUtil.ecgQuality(value);
          qualityPoints.add(healyBaseMeasuremenetData as HealyECGQualityData);
          break;
        case DeviceCmd.resultEcgPpg:
          healyBaseMeasuremenetData = ResolveUtil.ecgResult(value);
          if (healyBaseMeasuremenetData is HealyEcgSuccessData) {
            healyBaseMeasuremenetData.qualityPoints = qualityPoints;
            healyBaseMeasuremenetData.ecgData = healyEcgDataList;
            healyBaseMeasuremenetData.ppgData = healyPPGDataList;
          }else if(healyBaseMeasuremenetData is HealyOnlyPPGFinish){
            healyBaseMeasuremenetData.ppgData = healyPPGDataList;
          }
          break;
      }
      if (!controller.isClosed) {
        controller.add(healyBaseMeasuremenetData!);
      }
      if (healyBaseMeasuremenetData is HealyEcgSuccessData) {
        streamSubscription.cancel();
      } else if (healyBaseMeasuremenetData is HealyEcgFailureData) {
        if (healyBaseMeasuremenetData.errorCode !=
                HealyEcgFailureDataFailedCode.measurementInProgress &&
            healyBaseMeasuremenetData.errorCode !=
                HealyEcgFailureDataFailedCode.doNotMove &&
            healyBaseMeasuremenetData.errorCode !=
                HealyEcgFailureDataFailedCode.leadShedding &&
            healyBaseMeasuremenetData.errorCode !=
                HealyEcgFailureDataFailedCode.leadConnection) {
          streamSubscription.cancel();
        }
      }
    });
    return controller.stream;
  }

  bool _ecgMeasuringData(List<int> values) {
    return values.isNotEmpty &&
        (values[0] == DeviceCmd.enableEcgPpg ||
            values[0] == DeviceCmd.ecgData ||
            values[0] == DeviceCmd.ppgData ||
            values[0] == DeviceCmd.ecgQuality ||
            values[0] == DeviceCmd.resultEcgPpg);
  }

  bool _workOutData(List<int> values) {
    debugPrint("notify${BleSdk.hex2String(values)}");
    return values.isNotEmpty &&
        (values[0] == DeviceCmd.startExercise ||
            values[0] == DeviceCmd.exerciseData);
  }

  @override
  Stream<HealyBaseMeasuremenetData> startEcgMessuringWithDuration(
      int duration) {
    _writeData(BleSdk.enableEcgPPgWithTime(duration));
    return _getEcgMeasuremenetDataStream();
  }

  @override
  Stream<HealyBaseMeasuremenetData> startOnlyPPGMessuringWithDuration(
      int duration) {
    _writeData(BleSdk.enableOnlyPPgWithTime(duration));
    return _getEcgMeasuremenetDataStream();
  }

  @override
  Future<bool> stopEcgMessuring() async {
    await _writeData(BleSdk.stopEcgPPg());
    return _filterValue(DeviceCmd.stopEcgPpg).then((value) => true);
  }

  //开启的时候有可能会失败，运动数据会从另外个api返回
  @override
  Stream<HealyBaseExerciseData> startWorkout(HealyWorkoutMode workoutMode) {
    _writeData(BleSdk.startExerciseMode(workoutMode));
    final StreamController<HealyBaseExerciseData> controller =
        StreamController<HealyBaseExerciseData>();
    StreamSubscription<List<int>>? streamSubscription;
    streamSubscription = bluetoothUtil
        .monitorNotify()
        .where((values) => _workOutData(values))
        .listen((value) {
      HealyBaseExerciseData? healyBaseExerciseData;
      switch (value[0]) {
        case DeviceCmd.startExercise:
          healyBaseExerciseData = ResolveUtil.enterWorkOutModeData(value);
          break;
        case DeviceCmd.exerciseData:
          healyBaseExerciseData = ResolveUtil.getActivityExerciseData(value);
          break;
      }
      if (!controller.isClosed) {
        controller.add(healyBaseExerciseData!);
      }
      if (healyBaseExerciseData is HealyExerciseData) {
        if (healyBaseExerciseData.heartRate == 255)
          streamSubscription!.cancel();
      }
    });

    return controller.stream;
  }

  @override
  Future<bool> stopWorkout() async {
    await _writeData(BleSdk.stopExerciseMode());
    return bluetoothUtil
        .monitorNotify()
        .where((values) =>
            values.isNotEmpty &&
            values[0] == DeviceCmd.exerciseData &&
            values[1] == 0Xff)
        .first
        .then((value) => true);
  }

  @override
  Future<String> getSerialNumber() async {
    await _writeData(BleSdk.getSerialNumber());
    return _filterValue(DeviceCmd.getSerialnumber)
        .then((value) => ResolveUtil.getSerialNumber(value));
  }

  @override
  Future<int> getStepTarget() async {
    await _writeData(BleSdk.getStepTarget());
    return _filterValue(DeviceCmd.getGoal)
        .then((value) => ResolveUtil.getGoal(value));
  }

  @override
  Future<bool> setStepTarget(int personalTarget) async {
    await _writeData(BleSdk.setStepTarget(personalTarget));
    return _filterValue(DeviceCmd.setGoal).then((value) => true);
  }

  @override
  Future<bool> enableCamera() async {
    await _writeData(BleSdk.enterCamera());
    return _filterValue(DeviceCmd.enterCamera).then((value) => true);
  }

  @override
  Future<bool> enableMusic() async {
    await _writeData(BleSdk.enableMusic());
    return _filterValue(DeviceCmd.enableMusic).then((value) => true);
  }

  @override
  Future<HealyDeviceBaseParameter> getDeviceBaseParameter() async {
    await _writeData(BleSdk.getDeviceInfo());
    return _filterValue(DeviceCmd.getDeviceInfo)
        .then((value) => ResolveUtil.getDeviceInfo(value));
  }

  @override
  Future<bool> setDeviceBaseParameter(
      HealyDeviceBaseParameter deviceBaseParameter) async {
    await _writeData(BleSdk.setDeviceInfo(deviceBaseParameter));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> enableWristOn(bool enable) async {
    await _writeData(BleSdk.enableWristOn(enable));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> setDistanceUnit(DistanceUnit distanceUnit) async {
    await _writeData(BleSdk.setDistanceUnit(distanceUnit));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> setTimeModeUnit(HourMode hourMode) async {
    await _writeData(BleSdk.setTimeModeUnit(hourMode));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> setVibrationLevel(int level) async {
    await _writeData(BleSdk.setVibrationLevel(level));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> setWearingWrist(WearingWrist wearingWrist) async {
    await _writeData(BleSdk.setWearingWrist(wearingWrist));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> disableANCS() async {
    await _writeData(BleSdk.disableANCS());
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> enableANCS() async {
    await _writeData(BleSdk.enableANCS());
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> setBaseHeartRate(int hr) async {
    await _writeData(BleSdk.setBaseHeartRate(hr));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> setBrightnessLevel(int level) async {
    await _writeData(BleSdk.setBrightnessLevel(level));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> setConnectVibration(bool enable) async {
    await _writeData(BleSdk.setConnectVibration(enable));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> setScreenOnTime(int level) async {
    await _writeData(BleSdk.setScreenOnTime(level));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> setSosEnable(bool enable) async {
    await _writeData(BleSdk.setSosEnable(enable));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> setWristOnSensitivity(int level) async {
    await _writeData(BleSdk.setWristOnSensitivity(level));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }

  @override
  Future<bool> setWeatherData(WeatherData weatherData) async {
    await _writeData(BleSdk.setWeather(weatherData));
    return _filterValue(DeviceCmd.setWeather).then((value) => true);
  }

//断开连接之后 index需要清零，否则会导致数据错乱;(怎么从外部把index清零或者取消订阅)
  Stream _getDataStream(int cmd, {DateTime? date}) {
    _writeData(_getWriteData(cmd, DataRead.readStart, date: date));
    int index = 0;
    final StreamController? controller = _getDataStreamController(cmd);
    final StreamSubscription streamSubscription = _getStreamSubscription(cmd);
    streamSubscription.onData((data) {
      final List<dynamic> list = _getResolveData(cmd, data as List<int>);
      if (!controller!.isClosed) {
        controller.add(list);
      }
      index++;
      final bool isEnd = _isDataResponseEnd(data, cmd);
      if (isEnd) {
        streamSubscription.cancel();
        controller.close();
      } else {
        if (index == 50) {
          index = 0;
          _writeData(_getWriteData(cmd, DataRead.readContinue, date: date));
        }
      }
    });
    return controller!.stream;
  }

  StreamSubscription<List<int>> _getStreamSubscription(int cmd) {
    return bluetoothUtil
        .monitorNotify()
        .where((values) => values.isNotEmpty && values[0] == cmd)
        .listen((element) {});
  }

  StreamController? _getDataStreamController(int cmd) {
    StreamController? controller;
    switch (cmd) {
      case DeviceCmd.getClock:
        controller = StreamController<List<HealyClock>>();
        break;
      case DeviceCmd.getTotalData:
        controller = StreamController<List<HealyDailyEvaluation>>();
        break;
      case DeviceCmd.getDetailData:
        controller = StreamController<List<HealyDailyEvaluationBlock>>();
        break;
      case DeviceCmd.getSleepData:
        controller = StreamController<List<HealySleepData>>();
        break;
      case DeviceCmd.getWorkOutData:
        controller = StreamController<List<HealyWorkoutData>>();
        break;
      case DeviceCmd.getHrvHistoryData:
        controller = StreamController<List<HealyEcgSuccessData>>();
        break;
      case DeviceCmd.getStaticHeartData:
        controller = StreamController<List<HealyStaticHeartRate>>();
        break;
      case DeviceCmd.getDynamicHeartData:
        controller = StreamController<List<HealyDailyDynamicHeartRate>>();
        break;
    }
    return controller;
  }

  List<int> _getWriteData(int cmd, DataRead dataRead, {DateTime? date}) {
    List<int>? writeValue;
    switch (cmd) {
      case DeviceCmd.getClock:
        writeValue = BleSdk.getAlarmClock(dataRead);
        break;
      case DeviceCmd.getTotalData:
        writeValue = BleSdk.getTotalData(dataRead, date: date);
        break;
      case DeviceCmd.getDetailData:
        writeValue = BleSdk.getDailyEvaluationBlocks(dataRead, date: date);
        break;
      case DeviceCmd.getSleepData:
        writeValue = BleSdk.getSleepData(dataRead, date: date);
        break;
      case DeviceCmd.getWorkOutData:
        writeValue = BleSdk.getWorkOutData(dataRead, date: date);
        break;
      case DeviceCmd.getHrvHistoryData:
        writeValue = BleSdk.getHealyEcgSuccessData(dataRead, date: date);
        break;
      case DeviceCmd.getStaticHeartData:
        writeValue = BleSdk.getStaticHeartRateData(dataRead, date: date);
        break;
      case DeviceCmd.getDynamicHeartData:
        writeValue = BleSdk.getDynamicHeartRateData(dataRead, date: date);
        break;
    }
    return writeValue!;
  }

  List<dynamic> _getResolveData(int cmd, List<int> value) {
    List<dynamic>? results;
    switch (cmd) {
      case DeviceCmd.getClock:
        results = ResolveUtil.getClockData(value);
        break;
      case DeviceCmd.getTotalData:
        results = ResolveUtil.getTotalHistoryStepData(value);
        break;
      case DeviceCmd.getDetailData:
        results = ResolveUtil.getDetailHistoryData(value);
        break;
      case DeviceCmd.getSleepData:
        results = ResolveUtil.getSleepHistoryData(value);
        break;
      case DeviceCmd.getWorkOutData:
        results = ResolveUtil.getWorkOutData(value);
        break;
      case DeviceCmd.getHrvHistoryData:
        results = ResolveUtil.getHrvHistoryData(value);
        break;
      case DeviceCmd.getStaticHeartData:
        results = ResolveUtil.getStaticHrHistoryData(value);
        break;
      case DeviceCmd.getDynamicHeartData:
        results = ResolveUtil.getDynamicHistoryData(value);
        break;
    }
    return results!;
  }

  Future<void> _writeData(List<int> value, {String? transactionId}) async {
    if (!isConnected()) return;
    await bluetoothUtil.writeData(Uint8List.fromList(value),
        transactionId: transactionId);
    final String write = BleSdk.hex2String(value);
    debugPrint("write: $write");
  }

  Future<List<int>> _filterValue(int cmd) async {
    if (!(bluetoothUtil.isConnected())) return [];
    return bluetoothUtil
        .monitorNotify()
        .where((values) => values.isNotEmpty && values[0] == cmd)
        .first;
  }

  Stream<List<int>> _filterValueStream(int cmd) {
    return bluetoothUtil
        .monitorNotify()
        .where((values) => values.isNotEmpty && values[0] == cmd);
  }

  Future<List<int>> _filterDeleteValue(int cmd) async {
    //if (!(await bluetoothUtil.isConnected())) return [];

    return bluetoothUtil
        .monitorNotify()
        .where((values) =>
            values.isNotEmpty && values[0] == cmd && values[1] == 0x99)
        .first;
  }

  //固件没有返回数据
  @override
  bool disableRealTimeStep() {
    // TODO add async
    _writeData(BleSdk.enableRealTimeStep(false));

    return true;
  }

  @override
  Stream<HealyRealTimeStep> enableRealTimeStep() {
    _writeData(BleSdk.enableRealTimeStep(true));
    final stepStreamController = StreamController<HealyRealTimeStep>();
    _filterValueStream(DeviceCmd.enableActivity).listen((event) {
      if (!stepStreamController.isClosed) {
        stepStreamController.add(ResolveUtil.getRealTimeStepData(event));
      }
    });

    return stepStreamController.stream;
  }

  //固件没有返回数据
  @override
  bool backWatchHomePage() {
    // TODO add async
    _writeData(BleSdk.backWatchHomePage());
    return true;
  }

  @override
  Future<bool> setDeviceId(String deviceID) async {
    await _writeData(BleSdk.setDeviceId(deviceID));
    return _filterValue(DeviceCmd.setDeviceId).then((value) => true);
  }

  @override
  Future<bool> setMCUReset() async {
    await _writeData(BleSdk.resetMCU());
    return _filterValue(DeviceCmd.mcuReset).then((value) => true);
  }

  @override
  Future<bool> setFactoryMode() async {
    await _writeData(BleSdk.reset());
    return _filterValue(DeviceCmd.cmdReset).then((value) => true);
  }

  @override
  Future<bool> deleteAllClock() async {
    await _writeData(BleSdk.getAlarmClock(DataRead.delete));
    return _filterDeleteValue(DeviceCmd.getClock).then((value) => true);
  }

  @override
  Future<bool> editClock(List<HealyClock> clockList) {
    final List<int> sendList = BleSdk.setClockData(clockList);
    const int maxLength = 160;
    final int sendLength = sendList.length;
    if (sendLength > maxLength) {
      const int size = maxLength ~/ 39; //一个包最多发的闹钟个数
      const int length = size * 39; //最大闹钟数占用的字节
      final int count = sendLength % length == 0
          ? sendLength ~/ length
          : (sendLength ~/ length) + 1; //需要多少个包来发送
      for (int i = 0; i < count; i++) {
        final int end = length * (i + 1);
        int endLength = length;
        if (end >= sendLength) endLength = sendLength - length * i;
        final List<int> data = List<int>.generate(endLength, (int index) {
          return 0;
        });
        BleSdk.arrayCopy(sendList, length * i, data, 0, endLength);
        _offerData(data);
      }
      _writeOfferData();
    } else {
      _writeData(sendList);
    }

    return _filterValue(DeviceCmd.setClock).then((value) => true);
  }

  @override
  Stream<List<HealyClock>> getAllClock() {
    return _getDataStream(DeviceCmd.getClock) as Stream<List<HealyClock>>;
  }

  Future<bool> sendResUpdateData(List<List<int>> value) {
    offerAllData(value);
    _writeOfferData();
    return _filterValue(DeviceCmd.resDataSend).then((value) => value[1] == 1);
  }

  //是否升级成功
  Future<bool> checkResUpdateData(List<int> value) {
    _writeData(value);
    return _filterValue(DeviceCmd.resCheck)
        .then((value) => value[1] == 2 && value[2] == 1);
  }

  //是否需要升级
  Future<HealyResUpdateData> checkNeedResUpdate(List<int> value) {
    _writeData(value);
    return _filterValue(DeviceCmd.resCheck).then((value) {
      return ResolveUtil.getHealyResUpdate(value);
    });
  }

  List<List<int>> quList = [];

  void _offerData(List<int> value) {
    quList.add(value);
  }

  void offerAllData(List<List<int>> value) {
    quList.addAll(value);
  }

  void _writeOfferData() {
    final List<int>? value = quList.isEmpty ? null : quList.removeAt(0);
    if (value == null || !isConnected()) return;
    bluetoothUtil
        .writeData(Uint8List.fromList(value))
        .whenComplete(() => _writeOfferData());
  }

  @override
  Future<bool> setNotifyData(HealyNotifier healyNotifier) async {
    await _writeData(BleSdk.setNotifyData(healyNotifier));
    return _filterValue(DeviceCmd.cmdNotify).then((value) => true);
  }

  @override
  Future<bool> enterDfuMode() {
    _writeData(BleSdk.startOTA());
    return _filterValue(DeviceCmd.startOta).then((value) => true);
    // cant read anymore after entering dfu mode
    // try {
    //   return _filterValue(DeviceCmd.startOta).then((value) => true);
    // } on Exception catch (e) {
    //   print(e.toString());
    //   return false;
    // }
  }

  @override
  Future<bool> sendHeartPackage(
      HealyHeartPackageData healyHeartPackageData) async {
    await _writeData(BleSdk.sendHeartPackage(healyHeartPackageData));
    return true;
  }

  @override
  Stream<HealyBaseExerciseData> startBreathingSession(
      HealyBreathingSession breathingSession) {
    _writeData(BleSdk.startBreath(breathingSession));
    final StreamController<HealyBaseExerciseData> controller =
        StreamController<HealyBaseExerciseData>();
    StreamSubscription streamSubscription = bluetoothUtil
        .monitorNotify()
        .where((values) => _workOutData(values))
        .listen((value) {});
    streamSubscription.onData((data) {
      HealyBaseExerciseData? healyBaseExerciseData;
      switch (data[0]) {
        case DeviceCmd.startExercise:
          healyBaseExerciseData = ResolveUtil.enterWorkOutModeData(data);
          break;
        case DeviceCmd.exerciseData:
          healyBaseExerciseData = ResolveUtil.getActivityExerciseData(data);
          break;
      }

      if (!controller.isClosed) {
        controller.add(healyBaseExerciseData!);
      }
      if (healyBaseExerciseData is HealyExerciseData) {
        if (healyBaseExerciseData.heartRate == 255) {
          controller.close();
          streamSubscription.cancel();
        }
      }
    });
    return controller.stream;
  }

  @override
  Future<bool> stopBreathingSession() async {
    await _writeData(BleSdk.stopBreathSession());
    return true;
    // return bluetoothUtil
    //     .monitorNotify()
    //     .where((values) =>
    //         values.isNotEmpty &&
    //         values[0] == DeviceCmd.exerciseData &&
    //         values[1] == 0Xff)
    //     .then((value) => true);
  }

  @override
  Stream<HealyFunction> listenFunctionMode() {
    final StreamController<HealyFunction> controller =
        StreamController<HealyFunction>();
    _filterValueStream(DeviceCmd.function).listen((value) {
      if (!controller.isClosed) {
        controller.add(ResolveUtil.function(value));
      }
    });
    return controller.stream;
  }

  @override
  Future<HealySleepModeData> getHealySleepMode() async {
    await _writeData(BleSdk.getSleepModeData());
    return _filterValue(DeviceCmd.getSleepMode)
        .then((value) => ResolveUtil.getSleepModeData(value));
  }

  @override
  Future<bool> setHealySleepMode(HealySleepModeData healySleepModeData) async {
    await _writeData(BleSdk.setSleepModeData(healySleepModeData));
    return _filterValue(DeviceCmd.setSleepMode).then((value) => true);
  }

  /// Send the query firmware version number to the server,
  /// if the firmware version number is not the latest,
  /// the server will return the Response that needs to be updated
  /// and the download link of the new firmware version
  ///
  /// [currentVersion] must be in format 'xxx', e.g. '000' or '1929';
  /// returns [downloadUrl] if update is available
  /// returns [null] if no update is available
  @override
  Future<String?> checkIfFirmwareUpdateAvailable(String currentVersion) async {
    final currentVersionConverted = currentVersion.replaceAll('.', '');

    final Map<String, dynamic> queryParameters = {};

    queryParameters["version"] = currentVersionConverted;
    // queryParameters["version"] = "000";
    queryParameters["type"] = "1929";

    final Response response = await Dio().get(
      "http://api.le-young.com/device/firmware/v2/update",
      queryParameters: queryParameters,
    );

    final Map<String, dynamic> mapResponse =
        json.decode(response.toString()) as Map<String, dynamic>;

    final DeviceVersionResponse deviceVersionResponse =
        DeviceVersionResponse.fromJson(mapResponse);

    // new version available to download
    if (deviceVersionResponse.msgCode == 1052) {
      final FirmwareData? firmwareData = deviceVersionResponse.firmwareData;

      // final String version = firmwareData.version;

      return firmwareData!.url;
    } else {
      return null;
    }
  }

  /// Download the firmware and decompress it
  /// The full firmware package is a zip package with three files:
  /// - firmware.zip (firmware upgrade package)
  /// - color565.bin (resource file upgrade package)
  /// - color565MD5.txt (md5 of the resource file)
  ///
  /// [downloadUrl] can be retrieved by calling [checkIfFirmwareUpdateAvailable]
  @override
  Stream<double> downloadLatestFirmwareUpdate(String downloadUrl) async* {
    debugPrint('downloadLatestFirmwareUpdate');
    final downloadProgressStream = StreamController<double>();

    final Directory directory = await getApplicationDocumentsDirectory();
    final String rootPath = directory.path;
    final String savePath = "$rootPath/update.zip";

    debugPrint('Firmware update will be saved here: $rootPath');

    await Dio().download(downloadUrl, savePath,
        onReceiveProgress: (receivedBytes, totalBytes) {
      final double progress = receivedBytes / totalBytes;
      addProgress(downloadProgressStream, progress / 3);
      log('Downloading Firmware update: $progress');
    });
    log('Downloading Firmware finished.');

    _unZipFirmwareUpdateFile(rootPath, savePath, downloadProgressStream);
    yield* downloadProgressStream.stream;
  }

  // helper method for download stream, add progress
  Future<void> addProgress(
      StreamController<double> stream, double progress) async {
    if (stream != null && !stream.isClosed) {
      stream.add(progress);
    }
  }

  /// TODO whats this for?
  // Future<bool> checkShouldUpgradeResourceFiles(String path) async {
  //
  //   final ResourceUpdateUtil resUpdateUtils =
  //       ResourceUpdateUtil(path);
  //
  //   final List<int> checkBytes =
  //       resUpdateUtils.checkAllFile(ResCmdMode.startCheck);
  //
  //   final HealyResUpdateData healyResUpdateData =
  //       await checkNeedResUpdate(checkBytes);
  //
  //   return healyResUpdateData.needUpdate;
  // }

  /// TODO whats this for?
  /*Future updateResourceFiles() async {
    resUpdateUtils.sendFileByte();
  }*/

  Future _unZipFirmwareUpdateFile(String rootPath, String zipFilePath,
      StreamController<double> progressStream) async {
    if (!File(zipFilePath).existsSync()) {
      return;
    }
    final List<int> bytes = File(zipFilePath).readAsBytesSync();
    final Archive archive = ZipDecoder().decodeBytes(bytes);

    for (final ArchiveFile file in archive) {
      if (file.isFile) {
        final List<int> data = file.content as List<int>;
        log('_unZipFirmwareUpdateFile: ${file.name}');

        var path = file.name;
        var filename = path.split("/").last;

        File("$rootPath/$filename")
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      }
    }

    await startDfuMode(rootPath, progressStream);
  }

  ///检测是否需要资源文件升级，还需先判断文件是否存在
  ///升级完成后会断开连接，此时需要重新连接
  startCheckResUpdate(StreamController<double> progressStream) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String rootPath = directory.path;
    final File binFile = File("$rootPath/color565.bin");
    if (!binFile.existsSync()) return;

    final resUpdateUtils = ResourceUpdateUtil(rootPath);
    final List<int> checkBytes =
        resUpdateUtils.checkAllFile(ResCmdMode.startCheck);
    final HealyResUpdateData healyResUpdateData =
        await checkNeedResUpdate(checkBytes);
    bool needUpdate = healyResUpdateData.needUpdate;
    debugPrint("resUpdate $needUpdate");
    if (needUpdate) {
      final healySetDeviceTime = await HealyWatchSDKImplementation.instance
          .setDeviceTime(DateTime.now());
      resUpdateUtils.maxLength = healySetDeviceTime.maxLength;
      startResUpdate(
          resUpdateUtils, healyResUpdateData.updateIndex, progressStream);
    }
  }

  startResUpdate(ResourceUpdateUtil resUpdateUtils, int startIndex,
      StreamController<double> progressStream) async {
    try {
      // aparently needs a artificial delay, becasue it works when a debugging breakpoint is set
      await Future.delayed(Duration(seconds: 1), () {});
      await resUpdateUtils.sendFileByte(startIndex,
          progressCallback: (progress) =>
              addProgress(progressStream, 1 / 3 + progress / 3));
    } on Exception catch (e) {
      debugPrint(e.toString());
      progressStream.addError(e);
    }
  }

  /// TODO what is "ota"
  Future<void> startOta(
      String id, String path, StreamController<double> progressStream) async {
    int dfuPercent = 0;
    bool isDfuMode = false;
    SharedPrefUtils.setIsFirmware(true);
    await NordicDfu.startDfu(
      id,
      path,
      progressListener:
          DefaultDfuProgressListenerAdapter(onProgressChangedHandle: (
        deviceAddress,
        percent,
        speed,
        avgSpeed,
        currentPart,
        partsTotal,
      ) {
        isDfuMode = percent != 100;
        dfuPercent = percent ?? 0;
        log('startOta: progressValue: $dfuPercent');
        addProgress(progressStream, 2 / 3 + (dfuPercent / 100) / 3);
      }, onDfuProcessStartedHandle: (address) {
        log("startOta: onDfuProcessStartedHandle");
      }, onDeviceConnectedHandle: (address) {
        isDfuMode = true;
        log("startOta: onDeviceConnectedHandle");
      }, onDfuCompletedHandle: (address) async {
        log("startOta: onComplete");
        SharedPrefUtils.setIsFirmware(false);
        bluetoothUtil.isFirmwareUpdating = false;
        HealyDevice? device = await SharedPrefUtils.getConnectedDevice();
        bluetoothUtil.reconnectDevice(device);
        progressStream.close();
      }, onErrorHandle: (deviceAddress, error, errorType, message) {
        progressStream.addError(Exception(message));
      }),
    );
  }

  /// TODO this maybe needs to be put in healy watch app
  /// Enter the upgrade mode (DFU = Device Firmware Update)
  Future<void> startDfuMode(
      String rootPath, StreamController<double> progressStream) async {
    try {
      bluetoothUtil.isFirmwareUpdating = true;
      await enterDfuMode();
      // implementation below seems to be deprecated, will stay in as comment since the whole update flow is still very shakey and might need to be reworked
      await searchDeviceAndUpdateFirmware(rootPath, progressStream);

      /// Android has the mac address of the device, you can directly calculate
      /// the mac address to enter dfu mode according to the nodric's dfu mac address change method
      ///
      ///
      // if (Platform.isAndroid) {
      //   final Peripheral peripheral = getConnectedDeviceUnsafe();
      //   final String id = peripheral.identifier;
      //   log("$id dfuModeAddress ${getDfuConvertAddress(id)}");
      //   await startOta(
      //       getDfuConvertAddress(id), "$rootPath/firmware.zip", progressStream);
      //
      // } else if (Platform.isIOS) {
      //   await searchDeviceAndUpdateFirmware(rootPath, progressStream);
      // }
    } on Exception catch (e) {
      log(e.toString());
      bluetoothUtil.isFirmwareUpdating = false;
      progressStream.addError(e);
    }
  }

  Future<void> searchDeviceAndUpdateFirmware(
      String rootPath, StreamController<double> progressStream) async {
    /// ios does not have the mac address of the device, you need to
    /// enter dfu mode first and then scan to the device that entered dfu mode,
    /// and finally pass in the uuid of the device

    StreamSubscription streamSubscription =
        scanResults(filterForName: "dfu").listen(
      (event) {},
    );
    streamSubscription.onData((data) async {
      for (DiscoveredDevice peripheral in data) {
        debugPrint("dfu " + peripheral.id.toString());
        streamSubscription.cancel();
        await cancelScanningDevices();
        await startOta(peripheral.id, "$rootPath/firmware.zip", progressStream);
      }
    });
  }

  /// After entering dfu mode, the mac address will change, (last bit +1)
  String getDfuConvertAddress(String address) {
    final List<String> macArray = address.split(":");
    final int length = macArray.length;
    final String lastHex = macArray[length - 1];
    final int value = int.parse(lastHex, radix: 16);
    final int covertValue = value + 1;

    String covertHex = covertValue.toRadixString(16);

    if (covertHex.length < 2) covertHex = "0$covertHex";

    final StringBuffer covertAddress = StringBuffer();

    for (int i = 0; i < length - 1; i++) {
      final String mac = macArray[i];
      covertAddress.write("$mac:");
    }

    covertAddress.write(covertHex);
    return covertAddress.toString();
  }

  void addSleepQuilty(List<int> lastSleepQuality, List<int> sleepQualityList) {
    final int lastLength = lastSleepQuality.length;
    if (lastLength == 24) {
      sleepQualityList.addAll(lastSleepQuality);
    } else {
      final List<int> addList = _generateValue(24); // 0 is valid sleep data
      for (int i = 0; i < lastLength; i++) {
        addList[i] = lastSleepQuality[i];
      }
      sleepQualityList.addAll(addList);
    }
  }

  List<int> _generateValue(int size) {
    final List<int> value = List<int>.generate(size, (int index) {
      return -1;
    });
    return value;
  }

  @override
  BleStatus getBluetoothState() {
    return bluetoothUtil.getBluetoothState();
  }

  @override
  Stream<DeviceConnectionState> connectionStateStream() {
    return bluetoothUtil.connectionStateStream();
  }

  @override
  Stream<BleStatus> listenBluetoothState({bool emitCurrentValue = true}) {
    return bluetoothUtil.bleManager.statusStream;
  }

  @override
  Stream<HealyBaseExerciseData> currentWorkoutData() {
    // TODO: implement currentWorkoutData
    StreamController<HealyBaseExerciseData> controller =
        StreamController<HealyBaseExerciseData>();
    _filterValueStream(DeviceCmd.exerciseData).listen((value) {
      if (!controller.isClosed) {
        controller.add(ResolveUtil.getActivityExerciseData(value));
      }
    });
    return controller.stream;
  }
  @override
  Future<bool> setAncsState(List<HealyNotifierMode> enableList) async {
    await _writeData(BleSdk.setAncsState(enableList));
    return _filterValue(DeviceCmd.setDeviceInfo).then((value) => true);
  }
  @override
  Future<bool> isWorkoutRunning() {
    // TODO: implement isWorkoutRunning
    throw UnimplementedError();
  }

  @override
  Stream<List<HealyCombinedSleepData>> getAllCombinedSleepData() {
    // TODO: implement getAllCombinedSleepData
    Stream<List<HealySleepData>> sleepList = getAllSleepData();
    List<HealySleepData> list = [];
    StreamController<List<HealyCombinedSleepData>> streamController =
        StreamController();
    sleepList.listen((event) {
      list.addAll(event);
    }, onDone: () => combineData(list, streamController));
    return streamController.stream;
  }

  combineData(List<HealySleepData> listSleep,
      StreamController<List<HealyCombinedSleepData>> streamController) {
    Stream<List<HealyStaticHeartRate>> heartRateList = getAllStaticHeartRates();
    List<HealyStaticHeartRate> list = [];
    heartRateList.listen((event) {
      list.addAll(event);
    }, onDone: () => {combineDataSleep(streamController, listSleep, list)});
  }

  Duration getDifference(DateTime dateTime, DateTime nextTime) {
    return dateTime.difference(nextTime);
  }

  combineDataSleep(
      StreamController<List<HealyCombinedSleepData>> streamController,
      List<HealySleepData> sleeps,
      List<HealyStaticHeartRate> hrs) {
    int length = sleeps.length;
    List<HealyCombinedSleepData> listDatas = [];
    HealyCombinedSleepData? healyCombinedSleepData;
    HealySleepData? lastHealySleepData;
    for (int i = length - 1; i >= 0; i--) {
      HealySleepData healySleepData = sleeps[i];
      DateTime dateTime = healySleepData.startDateTime;
      List<int> list = healySleepData.sleepQuality;
      if (healyCombinedSleepData != null) {
        Duration duration =
            getDifference(dateTime, lastHealySleepData!.startDateTime);
        int durationMinutes =
            duration.inMinutes - lastHealySleepData.sleepQuality.length * 5;
        if (durationMinutes > 30) {
          int totalSleepTime = healyCombinedSleepData.sleepQuality.length * 5;
          healyCombinedSleepData.endDateTime = healyCombinedSleepData
              .startDateTime
              .add(Duration(minutes: totalSleepTime));
          listDatas.add(healyCombinedSleepData);
          healyCombinedSleepData = HealyCombinedSleepData(
              startDateTime: healyCombinedSleepData.startDateTime);
          healyCombinedSleepData.sleepQuality.addAll(list);
        } else {
          healyCombinedSleepData.sleepQuality.addAll(list);
        }
      } else {
        healyCombinedSleepData =
            HealyCombinedSleepData(startDateTime: healySleepData.startDateTime);
        healyCombinedSleepData.sleepQuality.addAll(list);
      }
      lastHealySleepData = healySleepData;
      if (i == 0) {
        int totalSleepTime = healyCombinedSleepData.sleepQuality.length * 5;
        healyCombinedSleepData.endDateTime = healyCombinedSleepData
            .startDateTime
            .add(Duration(minutes: totalSleepTime));
        listDatas.add(healyCombinedSleepData);
      }
    }

    listDatas.forEach((healyCombinedSleepData) {
      DateTime startTime = healyCombinedSleepData.startDateTime;
      DateTime? endTime = healyCombinedSleepData.endDateTime;
      hrs.forEach((element) {
        DateTime dateTime = element.dateTime;
        if (dateTime.isAfter(startTime) && dateTime.isBefore(endTime!)) {
          healyCombinedSleepData.heartRate.add(element.heartRate);
        }
      });
    });
    streamController.add(listDatas);
  }
}
