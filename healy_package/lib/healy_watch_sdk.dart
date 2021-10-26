import 'dart:async';


import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:healy_watch_sdk/util/ble_sdk.dart';

import 'model/models.dart';
import 'util/bluetooth_conection_util.dart';

abstract class HealyWatchSDK {
  ///
  /// BLUETOOTH CONNECTION
  ///

  /// Starts scanning for healy watch devices and
  /// return an stream of devices as [BluetoothDevice]
  Stream<List<DiscoveredDevice>> scanResults(
      {String filterForName, List<String> ids});

  /// Cancels scanning for healy watch devices
  void cancelScanningDevices();

  /// returns [bool] wether or not a bluetooth device is properly connected and can be used
  bool isConnected();

  /// Connect to a healy watch device [BluetoothDevice]
  Future<void> connectDevice(DiscoveredDevice device);

  /// Disconnects connected healy watch device [BluetoothDevice]
  void disconnectDevice();

  /// reconnect a already connected device from a device identifier
  Future<DiscoveredDevice> reconnectDevice({bool autoReconnect = true});

  /// Get connected healy watch as [BluetoothDevice]
  /// returns [Future<BluetoothDevice>] || [null] (if no device connected)
  DiscoveredDevice getConnectedDevice();

  /// SYNCING
  Stream<HealyBaseModel> getAllDataFromWatch();

  ///Listen for connection state to healy watch
   Stream<ConnectionStateUpdate> connectionStateStream();
  //
  // ///asynchronously check and get current connection state to healy watch
   Future<BluetoothConnectionState> getConnectionState();
  //
  // /// get the BLE [BluetoothState] currently
  // /// needs to be handled in watch sdk since there can only be one bluetooth client
  BleStatus getBluetoothState();
  //
  // ///listen the BLE [BluetoothState]
   Stream<BluetoothConnectionState> listenBluetoothState({bool emitCurrentValue = true});

  ///
  /// BASIC INFORMATION FROM DEVICE
  ///

  /// Get time from device
  Future<DateTime> getDeviceTime();

  Future<String> getDeviceAddress();

  Future<int> getBatteryLevel();

  Future<String> getFirmwareVersion();

  Future<bool> setMCUReset();

  Future<bool> setDeviceId(String deviceID);

  Future<bool> setStepTarget(int personalTarget);

  Future<int> getStepTarget();

  Future<HealyDeviceBaseParameter> getDeviceBaseParameter();

  Future<bool> setDeviceBaseParameter(
      HealyDeviceBaseParameter deviceBaseParameter);

  Future<bool> setDistanceUnit(DistanceUnit distanceUnit);

  Future<bool> setTimeModeUnit(HourMode hourMode);

  // ignore: avoid_positional_boolean_parameters
  Future<bool> enableWristOn(bool enable);

  Future<bool> setWearingWrist(WearingWrist wearingWrist);

  Future<bool> setVibrationLevel(int level);

  Future<bool> disableANCS();

  Future<bool> enableANCS();

  Future<bool> setBaseHeartRate(int hr);

  // ignore: avoid_positional_boolean_parameters
  Future<bool> setConnectVibration(bool enable);

  Future<bool> setBrightnessLevel(int level);

  // ignore: avoid_positional_boolean_parameters
  Future<bool> setSosEnable(bool enable);

  Future<bool> setWristOnSensitivity(int sensitivity);

  Future<bool> setScreenOnTime(int screenOnTime);

  Future<bool> setWeatherData(WeatherData weatherData);

  Stream<List<HealyClock>> getAllClock();

  Future<bool> editClock(List<HealyClock> clockList);

  Future<bool> deleteAllClock();

  Future<bool> setFactoryMode();

  Future<bool> enterDfuMode();

  Future<bool> setNotifyData(HealyNotifier healyNotifier);

  /// Set device time from given [DateTime]
  /// returns true if success and false if failure
  Future<HealySetDeviceTime> setDeviceTime(DateTime deviceTime);

  /// Set user information using [HealyUserInformation]
  /// returns true if success and false if failure
  Future<bool> setUserInformation(HealyUserInformation userInformation);

  /// Gets userinformation from device
  Future<HealyUserInformation> getUserInformation();

  ///
  /// ACTIVITY DATA
  ///
  Stream<HealyRealTimeStep> enableRealTimeStep();

  bool disableRealTimeStep();

  /// Returns all available workout types
  Future<HealyWorkoutType> getAllWorkoutTypes();

  /// Returns all selected workout types
  Future<HealyWorkoutType> getSelectedWorkoutTypes();

  /// Sets selected workout types
  /// returns true if success and false if failure
  Future<bool> setSelectedWorkoutTypes(HealyWorkoutType workoutTypes);

//  /// Returns all watch face styles
//  Future<List<HealyWatchFaceStyle>> getAllWatchFaceStyles();

  /// Returns selected watch face style
  Future<HealyWatchFaceStyle> getSelectedWatchFaceStyles();

  /// Sets watch face style
  /// returns true if success and false if failure
  Future<bool> setWatchFaceStyle(HealyWatchFaceStyle watchFaceStyle);

  /// Sets sedentary reminder using specified settings
  /// returns true if success and false if failure
  Future<bool> setSedentaryReminder(
    HealySedentaryReminderSettings reminderSettings,
  );

  /// Gets sedentary reminder settings
  Future<HealySedentaryReminderSettings> getSedentaryReminderSettings();

  /// Set workout reminder using settings
  /// returns true if success and false if failure
  Future<bool> setWorkoutReminder(
    HealyWorkoutReminderSettings reminderSettings,
  );

  /// Get workout reminder settings
  Future<HealyWorkoutReminderSettings> getWorkoutReminderSettings();

  /// Get heart rate messurement settings
  Future<HealyHeartRateMeasurementSettings> getHeartRateMessurementSettings();

  /// Set heart rate messurement settings
  /// returns true if success and false if failure
  Future<bool> setHeartRateMeasurementSettings(
    HealyHeartRateMeasurementSettings settings,
  );

  ///
  /// ECG DATA
  ///

  /// Returns a stream of [HealyBaseMeasuremenetData]
  Stream<HealyBaseMeasuremenetData> startEcgMessuring();

  Stream<HealyBaseMeasuremenetData> startOnlyPPGMeasuring();

  /// Returns a stream of [HealyBaseMeasuremenetData] by given [duration]
  Stream<HealyBaseMeasuremenetData> startEcgMessuringWithDuration(int duration);
  Stream<HealyBaseMeasuremenetData> startOnlyPPGMessuringWithDuration(int duration);

  /// Should stop collecting ecg data
  /// returns true if success and false if failure
  Future<bool> stopEcgMessuring();

  ///
  /// ACTIVITY DATA
  ///

  /// Should return all segmented activities for all collected data
  Stream<List<HealyDailyEvaluationBlock>> getAllDailyEvaluationBlocks(
      {DateTime date});

  /// Deletes all available data for the daily evaluation blocks
  /// returns true if success and false if failure
  Future<bool> deleteDailyEvaluationBlocks();

  ///
  /// 此处date不是指根据指定的日期返回指定日期的数据（固件没有根据指定日期返回数据的api），而是指返回此指定时间当天以及当天之后的数据，
  /// Here "date" does not refer to returning data for a specified date based on a specified date (firmware does not have an api that returns data based on a specified date), but rather returning data for the day of this specified time and afterwards.
  /// 用意是加快同步数据的速度（把上次同步过的数据的最后的时间保存，然后下次同步的时候把这个时间传进来
  /// The intent is to speed up the syncing  speed of data (save the time when the data was synced last time, and then pass that time in the next sync)
  /// ，固件就会在返回这个时间以及这个时间之后的数据;不传时间的话固件会把所有的数据都返回导致同步速度变慢；其他模式的DateTime也是这种意思）
  /// the firmware will then return data of this time and afterwards; without passing the time, the firmware will return all the data and slow down the syncing speed; this is what is meant by DateTime in other modes as well)
  Stream<List<HealyDailyEvaluation>> getDailyEvaluationByDay({DateTime date});

  /// Should delete all daily activities
  /// returns true if success and false if failure
  Future<bool> deleteAllDailyActivities();

  /// Returns all collected dynamic heartrates
  Stream<List<HealyDailyDynamicHeartRate>> getAllDynamicHeartRates(
      {DateTime date});

  /// Deletes all heartrates
  /// returns true if success and false if failure
  Future<bool> deleteAllDynamicHeartRates();

  /// Returns all collected static heartrates
  Stream<List<HealyStaticHeartRate>> getAllStaticHeartRates({DateTime date});

  /// Deletes all static heartrates
  /// returns true if success and false if failure
  Future<bool> deleteAllStaticHeartRates();

  /// Returns all collected sleep data
  Stream<List<HealySleepData>> getAllSleepData({DateTime date});

  /// Deletes all collected sleep data
  /// returns true if success and false if failure
  Future<bool> deleteAllSleepData();

  /// Returns all exercise data
  Stream<List<HealyWorkoutData>> getAllWorkoutData({DateTime date});

  /// Deletes all exercise data
  Future<bool> deleteAllWorkoutData();

  /// Returns all collected HRV data as list
  Stream<List<HealyEcgSuccessData>> getAllHRVData();

  /// Deletes all HRV data
  /// returns true if success and false if failure
  Future<bool> deleteAllECGData();

  /// Starts workout mode on healy watch.
  /// return an stream of data as [HealyExerciseData]
  Stream<HealyBaseExerciseData> startWorkout(HealyWorkoutMode workoutMode);

  /// Stops workout mode on healy watch
  Future<bool> stopWorkout();

  Stream<HealyBaseExerciseData> startBreathingSession(
      HealyBreathingSession breathingSession);

  Future<bool> stopBreathingSession();

  Future<bool> sendHeartPackage(HealyHeartPackageData healyHeartPackageData);

  /// Returns the serial number of Healy watch
  Future<String> getSerialNumber();

  /// Enable the camera on device
  Future<bool> enableCamera();

  /// Enable the music on device
  Future<bool> enableMusic();

  bool backWatchHomePage();

  Stream<HealyFunction> listenFunctionMode();

  Future<bool> setHealySleepMode(
    HealySleepModeData healySleepModeData,
  );

  /// Gets sedentary reminder settings
  Future<HealySleepModeData> getHealySleepMode();

  /// Firmware Update
  Future<String?> checkIfFirmwareUpdateAvailable(String currentVersion);

  Stream<double> downloadLatestFirmwareUpdate(String downloadUrl);
}
