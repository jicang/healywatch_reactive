import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../bleconst/device_cmd.dart';
import '../model/models.dart';

/// Get the data tool class that needs to be sent to the watch
/// the data returned are of type List<int>, which sends the returned data to the watch
///
/// ```
///   List<int>list=BleSdk.getTimeValue();
///   characteristicData.write(list);
/// ```
///
/// the received data returned from the watch is then passed to
/// [ResolveUtil.receiveUpdateValue(List<int> value)]
/// to conduct analysis
/// characteristic is the class that BLE communications uses to send data,
/// which varies depending on the BLE tool used;
/// the BLE tool used inside the demo is a third-party plugin flutter_blue
class BleSdk {
  static List<int> generateValue(int size) {
    final List<int> value = List<int>.generate(size, (int index) {
      return 0;
    });
    return value;
  }

  /// 初始化要发送的数据，16个字节，没有设置的位置都默认为0
  static List<int> _generateInitValue() {
    return generateValue(16);
  }

  /// crc validation
  static void crcValue(List<int> list) {
    int crcValue = 0;
    for (final int value in list) {
      crcValue += value;
    }
    list[15] = crcValue & 0xff;
  }

  /// 十进制转bcd码（23 -> 0x23）
  static int _getBcdValue(int value) {
    String data = value.toString();
    if (data.length > 2) data = data.substring(2);
    return int.parse(data, radix: 16);
  }

  /// 字节数组转16进制字符串
  static String hex2String(List<int> values) {
    final StringBuffer stringBuffer = StringBuffer();
    for (final int value in values) {
      String hex = value.toRadixString(16);
      if (hex.length < 2) hex = "0$hex";
      stringBuffer.write("$hex ");
    }
    return stringBuffer.toString();
  }

  static int _getWeekEnable(List<int> weekEnableList) {
    int weekSet = 0;
    for (int i = 0; i < weekEnableList.length; i++) {
      if (weekEnableList[i] == 1) weekSet += pow(2, i) as int;
    }
    return weekSet;
  }

  /// copying array of data
  static void arrayCopy(
      List<int> source, int srcPos, List<int> dest, int destPos, int length) {
    for (int i = 0; i < length; i++) {
      dest[destPos + i] = source[srcPos + i];
    }
  }

  static void _getReadData(List<int> value, DataRead dataRead) {
    int mode = 0;
    switch (dataRead) {
      case DataRead.readStart:
        mode = 0;
        break;
      case DataRead.readContinue:
        mode = 2;
        break;
      case DataRead.delete:
        mode = 0x99;
        break;
    }
    value[1] = mode;
  }

  static int _getDeviceInfoValue(dynamic value) {
    int result = 0;
    if (value == null) return result;
    if (value is bool) {
      result = value ? 0x81 : 0x80;
    } else if (value is int) {
      result = value == 0 ? 0 : value + 0x80;
    }
    return result;
  }

  /// get time
  ///
  /// Response [GetDeviceTimeResponse]
  static List<int> getDeviceTime() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getTime;
    crcValue(value);
    return value;
  }

  /// setting device time
  ///
  /// Response [SetDeviceTimeResponse]
  static List<int> setDeviceTime(DateTime dateTime) {
    final List<int> value = _generateInitValue();
    final int year = dateTime.year;
    final int month = dateTime.month;
    final int day = dateTime.day;
    final int hour = dateTime.hour;
    final int minute = dateTime.minute;
    final int second = dateTime.second;
    value[0] = DeviceCmd.setTime;
    value[1] = _getBcdValue(year);
    value[2] = _getBcdValue(month);
    value[3] = _getBcdValue(day);
    value[4] = _getBcdValue(hour);
    value[5] = _getBcdValue(minute);
    value[6] = _getBcdValue(second);
    crcValue(value);
    return value;
  }

  /// get device mac address
  ///
  /// Response [DeviceMacAddressResponse]
  static List<int> getMacAddress() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getAddress;
    crcValue(value);
    return value;
  }

  /// get device battery level
  ///
  /// Response [BatteryResponse]
  static List<int> getBatteryLevel() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getBatteryLevel;
    crcValue(value);
    return value;
  }

  /// get device serial number
  ///
  /// Response [getSerialNumber]
  static List<int> getSerialNumber() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getSerialnumber;
    crcValue(value);
    return value;
  }

  /// get device version
  ///
  /// Response [FirmwareVersionResponse]
  static List<int> getFirmwareVersion() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getVersion;
    crcValue(value);
    return value;
  }

  /// reboot device
  ///
  /// Response [MCUResetResponse]
  static List<int> resetMCU() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.mcuReset;
    crcValue(value);
    return value;
  }

  /// enter dfu (firmware update) mode
  static List<int> startOTA() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.startOta;
    crcValue(value);
    return value;
  }

  /// reset to factory mode
  static List<int> reset() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.cmdReset;
    crcValue(value);
    return value;
  }

  /// get device parameter info
  ///
  /// Response [DeviceBaseResponse]
  static List<int> getDeviceInfo() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getDeviceInfo;
    crcValue(value);
    return value;
  }

  /// set watch parameters
  static List<int> setDeviceInfo(HealyDeviceBaseParameter deviceBaseParameter) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.setDeviceInfo;
    if (deviceBaseParameter.distanceUnit != null) {
      value[1] =
          deviceBaseParameter.distanceUnit == DistanceUnit.imperial ? 0x81 : 0x80;
    }
    if (deviceBaseParameter.hourMode != null) {
      value[2] =
          deviceBaseParameter.hourMode == HourMode.hourMode_12 ? 0X81 : 0X80;
    }

    value[3] = _getDeviceInfoValue(deviceBaseParameter.wristOnEnable);
    if (deviceBaseParameter.wearingWrist != null) {
      value[4] =
          deviceBaseParameter.wearingWrist == WearingWrist.left ? 0x81 : 0x80;
    }

    value[5] = _getDeviceInfoValue(deviceBaseParameter.vibrationLevel);
    value[6] = _getDeviceInfoValue(deviceBaseParameter.ancsState);
    value[9] = _getDeviceInfoValue(deviceBaseParameter.baseHeart);
    value[10] = _getDeviceInfoValue(deviceBaseParameter.connectVibration);
    value[11] = _getDeviceInfoValue(deviceBaseParameter.brightnessLevel);
    value[12] = _getDeviceInfoValue(deviceBaseParameter.sosEnable);
    value[13] = _getDeviceInfoValue(deviceBaseParameter.wristOnSensitivity);
    value[14] = _getDeviceInfoValue(deviceBaseParameter.screenOnTime);
    crcValue(value);
    return value;
  }

  /// set distance unit
  static List<int> setDistanceUnit(DistanceUnit distanceUnit) {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.distanceUnit = distanceUnit;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// set hour mode (12h/24h)
  static List<int> setTimeModeUnit(HourMode hourMode) {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.hourMode = hourMode;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// set wrist-on enablement
  ///
  /// enable（true trun-on，false trun-off）
  // ignore: avoid_positional_boolean_parameters
  static List<int> enableWristOn(bool enable) {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.wristOnEnable = enable;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// set wearing wrist (left/right)
  static List<int> setWearingWrist(WearingWrist wearingWrist) {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.wearingWrist = wearingWrist;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// （1-5）set vibration intensity level (1-5)
  static List<int> setVibrationLevel(int level) {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.vibrationLevel = level;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// Enable ancs
  ///
  /// ios send notification reminders to the watch through ancs
  ///
  /// android doesn't have ancs, sending notifications to the watch requires
  /// a call to [setNotifyData]
  /// if the watch has the ancs enabled on the ios side, ancs needs to
  /// be turned-off when connect with android, otherwise the system pairing
  /// box will pop up；
  static List<int> disableANCS() {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.ancsState = false;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// enable ancs
  static List<int> enableANCS() {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.ancsState = true;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// set base heart rate (>40)
  static List<int> setBaseHeartRate(int hr) {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.baseHeart = hr;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// motor vibration when device connection
  // ignore: avoid_positional_boolean_parameters
  static List<int> setConnectVibration(bool enable) {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.connectVibration = enable;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// set screen brightness level (1 brightest, 15 darkest)
  static List<int> setBrightnessLevel(int level) {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.brightnessLevel = level;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// set SOS interface display
  // ignore: avoid_positional_boolean_parameters
  static List<int> setSosEnable(bool enable) {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.sosEnable = enable;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// set wrist-on sensitivity (1, 2, 3)
  static List<int> setWristOnSensitivity(int sensitivity) {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.wristOnSensitivity = sensitivity;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// set screen-on time (1~8)
  static List<int> setScreenOnTime(int screenOnTime) {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.screenOnTime = screenOnTime;
    return setDeviceInfo(deviceBaseParameter);
  }

  /// get detailed work out data
  ///
  /// date is the most recent date in the last data sync, passing in
  /// the date reduces the sync time by not syncing the synced data
  /// (firmware is not complete yet) format（2020/05/06 08:50:55）
  ///
  ///  Response [DetailDataResponse]
  static List<int> getDailyEvaluationBlocks(DataRead dataRead,
      {DateTime? date}) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getDetailData;
    _getReadData(value, dataRead);
    _insertDateValue(value, date);
    crcValue(value);
    return value;
  }

  static List<int> deleteAllDailyEvaluationBlocks() {
    return getDailyEvaluationBlocks(DataRead.delete);
  }

  /// notification reminder
  static List<int> setNotifyData(HealyNotifier healyNotifier) {
    final String info = healyNotifier.info;
    final String title = healyNotifier.title;
    final List<int> infoValue =
        info.isEmpty ? generateValue(1) : _getInfoValue(info, 60);
    final List<int> titleValue =
        title.isEmpty ? generateValue(1) : _getInfoValue(title, 60);
    // List<int> value = new byte[infoValue.length + 3];
    final List<int> value = generateValue(124);
    value[0] = DeviceCmd.cmdNotify;
    value[1] = healyNotifier.healyNotifierMode == HealyNotifierMode.dataStopTel
        ? 0xff
        : healyNotifier.healyNotifierMode.index;
    value[2] = infoValue.length;
    arrayCopy(infoValue, 0, value, 3, infoValue.length);
    value[63] = titleValue.length;
    arrayCopy(titleValue, 0, value, 64, titleValue.length);
    return value;
  }

  /// Get total workout data
  ///
  /// date is the most recent date in the last data sync, passing
  /// in the date reduces the sync time by not syncing the synced data
  /// (firmware is not complete yet)；format（2020/05/06）
  ///
  ///  Response [TotalDataResponse]
  static List<int> getTotalData(DataRead dataRead, {DateTime ?date}) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getTotalData;
    _getReadData(value, dataRead);
    _insertDateValueNoH(value, date);
    crcValue(value);
    return value;
  }

  static List<int> deleteAllTotalData() {
    return getTotalData(DataRead.delete);
  }

  /// read alarm
  static List<int> getAlarmClock(DataRead dataRead) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getClock;
    _getReadData(value, dataRead);
    crcValue(value);
    return value;
  }

  /// set alarm
  ///
  /// the length of the alarm data received here may exceed the length of the
  /// data that the device can send at one time, so it may need to send it in sections
  /// the length of data the device can send at one time is in the
  /// callback after a successful time setting[SetDeviceTimeResponse.maxLength]
  static List<int> setClockData(List<HealyClock> clockList) {
    final int size = clockList.length;
    const int length = 39;
    final List<int> totalValue =
        List<int>.generate(length * size + 2, (int index) {
      return 0;
    });
    for (int i = 0; i < size; i++) {
      final HealyClock clock = clockList[i];
      final List<int> value = List<int>.generate(length, (int index) {
        return 0;
      });
      final String content = clock.content;
      final List<int> infoValue = _getInfoValue(content, 30);
      value[0] = DeviceCmd.setClock;
      value[1] = size;
      value[2] = i;
      value[3] = clock.enable ? 1 : 0;
      value[4] = clock.healyClockMode.index;
      value[5] = _getBcdValue(clock.hour);
      value[6] = _getBcdValue(clock.minute);
      value[7] = _getWeekEnable(clock.weekEnableList);
      value[8] = infoValue.isEmpty ? 1 : infoValue.length;
      arrayCopy(infoValue, 0, value, 9, infoValue.length);
      arrayCopy(value, 0, totalValue, i * length, value.length);
    }
    totalValue[totalValue.length - 2] = DeviceCmd.setClock;
    totalValue[totalValue.length - 1] = 0xff;
    return totalValue;
  }

  /// message content needed to be sent is converted to List<int>
  static List<int> _getInfoValue(String info, int maxLength) {
    if (info == null || info.isEmpty) return [];
    final List<int> nameBytes = utf8.encode(info);
    if (nameBytes.length >= maxLength) {
      /// two commands in total 32 bytes, with only 24 bytes of content.
      /// （32-2*（1cmd+1 Message type + 1 length + 1 validation））
      final List<int> real = List<int>.generate(maxLength, (int index) {
        return 0;
      });
      final List<int> chars = info.codeUnits;
      int length = 0;
      for (int i = 0; i < chars.length; i++) {
        final String s = chars[i].toString();
        final List<int> nameB = utf8.encode(s);
        if (length + nameB.length == maxLength) {
          arrayCopy(nameBytes, 0, real, 0, real.length);
          return real;
        } else if (length + nameB.length > maxLength) {
          /// >24 will result in a byte not being sent to the lower machine causing garbled code
          arrayCopy(nameBytes, 0, real, 0, length);
          return real;
        }
        length += nameB.length;
      }
    }

    return nameBytes;
  }

  /// setting sedentary reminder
  ///
  /// Response [SetSedentaryReminderResponse]
  static List<int> setSedentaryReminder(
      HealySedentaryReminderSettings sedentaryReminder) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.setSedentaryReminder;
    value[1] = _getBcdValue(sedentaryReminder.startHour);
    value[2] = _getBcdValue(sedentaryReminder.startMinute);
    value[3] = _getBcdValue(sedentaryReminder.endHour);
    value[4] = _getBcdValue(sedentaryReminder.endMinute);
    value[5] = _getWeekEnable(sedentaryReminder.daysInWeek);
    value[6] = sedentaryReminder.interval;
    value[7] = sedentaryReminder.minimumStepsGoal & 0xff;
    value[8] = sedentaryReminder.isEnabled ? 1 : 0;
    crcValue(value);
    return value;
  }

  /// get sedentary reminder
  ///
  /// Response [GetSedentaryReminderResponse]
  static List<int> getSedentaryReminder() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getSedentaryReminder;
    crcValue(value);
    return value;
  }

  static List<int> setSleepModeData(HealySleepModeData healySleepModeData) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.setSleepMode;
    value[1] = 0x81;
    value[2] = _getBcdValue(healySleepModeData.startHour);
    value[3] = _getBcdValue(healySleepModeData.startMin);
    value[4] = _getBcdValue(healySleepModeData.endHour);
    value[5] = _getBcdValue(healySleepModeData.endMin);
    value[6] = healySleepModeData.isEnabled ? 0x81 : 0x80;
    crcValue(value);
    return value;
  }

  static List<int> getSleepModeData() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getSleepMode;
    crcValue(value);
    return value;
  }

  /// get work out reminder
  ///
  /// Response [GetWorkOutReminderResponse]
  static List<int> getWorkOutReminder() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getWorkoutReminder;
    crcValue(value);
    return value;
  }

  /// set work out reminder
  ///
  /// Response [SetWorkOutReminderResponse]
  static List<int> setWorkOutReminder(
      HealyWorkoutReminderSettings workOutReminder) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.setWorkoutReminder;
    value[1] = _getBcdValue(workOutReminder.hour);
    value[2] = _getBcdValue(workOutReminder.minute);
    value[3] = workOutReminder.days; //天数
    value[4] = _getWeekEnable(workOutReminder.daysInWeek);
    value[5] = workOutReminder.isEnabled ? 1 : 0;
    final int min = workOutReminder.duration;
    value[6] = min & 0xff;
    value[7] = (min >> 8) & 0xff;
    crcValue(value);
    return value;
  }

  /// turn on real-time step counting
  ///
  /// enable（true trun-on，false turn-off）
  // ignore: avoid_positional_boolean_parameters
  ///Response [RealTimeStepResponse]
  // ignore: avoid_positional_boolean_parameters
  static List<int> enableRealTimeStep(bool enable) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.enableActivity;
    value[1] = enable ? 1 : 0;
    crcValue(value);
    return value;
  }

  /// get hrv measurement result history data
  static List<int> getHealyEcgSuccessData(DataRead dataRead, {DateTime ?date}) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getHrvHistoryData;
    _getReadData(value, dataRead);
    _insertDateValue(value, date);
    crcValue(value);
    return value;
  }

  static List<int> deleteAllHRVHistoryData() {
    return getHealyEcgSuccessData(DataRead.delete);
  }

  /// set automatic heart rate monitor time interval
  ///
  /// Response [SetAutoMeasureHeartRateResponse]
  static List<int> setAutoHeartZone(
      HealyHeartRateMeasurementSettings autoHeart) {
    final List<int> value = _generateInitValue();
    final int time = autoHeart.intervalTime;
    value[0] = DeviceCmd.setAutoHeart;
    value[1] = autoHeart.measurementMode.index;
    value[2] = _getBcdValue(autoHeart.startHour);
    value[3] = _getBcdValue(autoHeart.startMinute);
    value[4] = _getBcdValue(autoHeart.endHour);
    value[5] = _getBcdValue(autoHeart.endMinute);
    value[6] = _getWeekEnable(autoHeart.daysInWeek);
    value[7] = time & 0xff;
    value[8] = (time >> 8) & 0xff;
    crcValue(value);
    return value;
  }

  /// get automatic heart rate monitor time interval
  ///
  /// Response [GetAutoMeasureHeartRateResponse]
  static List<int> getAutoHeartZone() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getAutoHeart;
    crcValue(value);
    return value;
  }

  /// get dynamic heart rate data
  ///
  /// date is the most recent date in the last data sync,
  /// passing in the date reduces the sync time by not syncing
  /// the synced data (firmware is not complete yet);
  /// format（2020/05/06 08:50:55）
  ///
  /// Response [DynamicHeartRateDataResponse]
  static List<int> getDynamicHeartRateData(DataRead dataRead, {DateTime ?date}) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getDynamicHeartData;
    _getReadData(value, dataRead);
    _insertDateValue(value, date);
    crcValue(value);
    return value;
  }

  static List<int> deleteAllDynamicHeartRateData() {
    return getDynamicHeartRateData(DataRead.delete);
  }

  /// get work out mode history data
  ///
  /// date is the most recent date in the last data sync,
  /// passing in the date reduces the sync time by not syncing
  /// the synced data (firmware is not complete yet)；
  /// format（2020/05/06 08:50:55）
  ///
  /// Response [ExerciseDataResponse]
  static List<int> getWorkOutData(DataRead dataRead, {DateTime ?date}) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getWorkOutData;
    _getReadData(value, dataRead);
    _insertDateValue(value, date);
    crcValue(value);
    return value;
  }

  static List<int> deleteAllWorkOutData() {
    return getWorkOutData(DataRead.delete);
  }

  /// get static heart rate history data
  ///
  /// date is the most recent date in the last data sync,
  /// passing in the date reduces the sync time by not syncing
  /// the synced data (firmware is not complete yet)；
  /// format（2020/05/06 08:50:55）
  ///
  /// Response [StaticHeartRateDataResponse]
  static List<int> getStaticHeartRateData(DataRead dataRead, {DateTime ?date}) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getStaticHeartData;
    _getReadData(value, dataRead);
    _insertDateValue(value, date);
    crcValue(value);
    return value;
  }

  static List<int> deleteAllStaticHeartRateData() {
    return getStaticHeartRateData(DataRead.delete);
  }

  /// set watch step goal
  ///
  /// Response [SetStepTargetResponse]
  static List<int> setStepTarget(int personalTarget) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.setGoal;
    value[4] = (personalTarget >> 24) & 0xff;
    value[3] = (personalTarget >> 16) & 0xff;
    value[2] = (personalTarget >> 8) & 0xff;
    value[1] = personalTarget & 0xff;
    crcValue(value);
    return value;
  }

  /// get watch step goal
  ///
  /// Response [GetStepTargetResponse]
  static List<int> getStepTarget() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getGoal;
    crcValue(value);
    return value;
  }

  /// set device ID
  static List<int> setDeviceId(String deviceID) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.setDeviceId;
    int length=deviceID.length;
    for (int i = 0; i < length; i++) {
      value[i + 1] = deviceID.codeUnitAt(i);
    }
    crcValue(value);
    return value;
  }

  /// return to watch home page
  static List<int> backWatchHomePage() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.backHome;
    crcValue(value);
    return value;
  }

  /// get personal info set on watch
  ///
  /// Response [GetPersonalInfoResponse]
  static List<int> getUserInfo() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getUserInfo;
    crcValue(value);
    return value;
  }

  /// set personal info
  ///
  /// Response [SetPersonalInfoResponse]
  static List<int> setUserInfo(HealyUserInformation info) {
    final List<int> value = _generateInitValue();
    final int male = info.gender.index;
    final int age = info.age;
    final int height = info.heightInCm.toInt();
    final int weight = info.weightInKg.toInt();
    final int stepLength = info.stepLength;
    value[0] = DeviceCmd.setUserInfo;
    value[1] = male;
    value[2] = age;
    value[3] = height;
    value[4] = weight;
    value[5] = stepLength;
    crcValue(value);
    return value;
  }

  /// enter take photo mode on watch
  static List<int> enterCamera() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.enterCamera;
    crcValue(value);
    return value;
  }

  /// set watch face style
  static List<int> setWatchFaceStyle(int styleMode) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.watchFaceStyle;
    value[1] = styleMode;
    value[2] = 0;
    crcValue(value);
    return value;
  }

  /// get watch face style
  ///
  /// Response [getWatchFaceStyle]
  static List<int> getWatchFaceStyle() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.watchFaceStyle;
    value[2] = 1;
    crcValue(value);
    return value;
  }

  /// set the workout types displayed on the watch (up to 5)
  ///
  /// Response [SetWorkOutTypeResponse]
  static List<int> setWorkOutType(List<int> list) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.setWorkoutType;
    for (int i = 0; i < 5; i++) {
      value[i + 1] = 0xff;
    }
    int startIndex = 1;
    for (final int i in list) {
      value[startIndex] = (i < 6 ? i : i + 1);;
      startIndex++;
    }
    crcValue(value);
    return value;
  }

  /// get the work outtypes displayed on the watch
  ///
  /// Response [GetWorkOutTypeResponse]
  static List<int> getWorkOutType() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getWorkoutType;
    crcValue(value);
    return value;
  }

  /// music control enablement
  static List<int> enableMusic() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.enableMusic;
    value[1] = 3;
    value[2] = 4;
    crcValue(value);
    return value;
  }

  /// enter breathing session
  ///
  /// level(0,1,2)
  static List<int> startBreath(HealyBreathingSession healyBreathingSession) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.startExercise;
    value[1] = 1;
    value[2] = 6;
    value[3] = healyBreathingSession.level;
    value[4] = healyBreathingSession.durationInSeconds;
    crcValue(value);
    return value;
  }

  /// enter workout mode
  ///
  /// Response [EnterWorkOutModeResponse]
  static List<int> startExerciseMode(HealyWorkoutMode healyWorkoutMode) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.startExercise;
    value[1] = 1;
    value[2] = healyWorkoutMode.index;
    crcValue(value);
    return value;
  }

  /// exit workout mode
  ///
  /// Response [WorkOutModeDeviceDataResponse]
  static List<int> stopExerciseMode() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.startExercise;
    value[1] = 4;
    crcValue(value);
    return value;
  }

  /// exit breathing session
  static List<int> stopBreathSession() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.startExercise;
    value[1] = 4;
    value[2] = 6;
    crcValue(value);
    return value;
  }

  /// start ecg/ppg measurement
  ///
  /// Response [EcgMeasureResultResponse]
  static List<int> enableEcgPPgWithLevel(int level) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.enableEcgPpg;
    value[1] = level;
    crcValue(value);
    return value;
  }

  ///start only ppg measurement
  ///
  /// Response [EcgMeasureResultResponse]
  static List<int> enableOnlyPPg() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.enableEcgPpg;
    value[1] = 4;
    value[5] = 0xaa;
    crcValue(value);
    return value;
  }

  static List<int> enableOnlyPPgWithTimeAndLevel(int level, int time) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.enableEcgPpg;
    value[1] = level;
    value[3] = time & 0xff;
    value[4] = (time >> 8) & 0xff;
    value[5] = 0xaa;
    crcValue(value);
    return value;
  }

  static List<int> enableEcgPPg() {
    return enableEcgPPgWithLevel(4);
  }

  /// start ecg/ppg measurement and set time
  ///
  /// Response [EcgMeasureResultResponse]
  static List<int> enableEcgPPgWithTimeAndLevel(int level, int time) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.enableEcgPpg;
    value[1] = level;
    value[3] = time & 0xff;
    value[4] = (time >> 8) & 0xff;
    crcValue(value);
    return value;
  }

  static List<int> enableEcgPPgWithTime(int time) {
    return enableEcgPPgWithTimeAndLevel(4, time);
  }

  static List<int> enableOnlyPPgWithTime(int time) {
    return enableOnlyPPgWithTimeAndLevel(4, time);
  }

  /// stop ecg/ppg measurement
  static List<int> stopEcgPPg() {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.stopEcgPpg;
    crcValue(value);
    return value;
  }

  /// get sleep movement data for the day
  ///
  /// date is the most recent date in the last data sync
  ///  Response [SleepDataResponse]
  static List<int> getSleepData(DataRead dataRead, {DateTime ?date}) {
    final List<int> value = _generateInitValue();
    value[0] = DeviceCmd.getSleepData;
    _getReadData(value, dataRead);
    _insertDateValue(value, date);
    crcValue(value);
    return value;
  }

  static List<int> deleteAllSleepData() {
    return getSleepData(DataRead.delete);
  }

  static void _insertDateValue(List<int> value, DateTime? dateTime) {
    if (dateTime == null) return;
    final int year = dateTime.year;
    final int month = dateTime.month;
    final int day = dateTime.day;
    final int hour = dateTime.hour;
    final int min = dateTime.minute;
    final int second = dateTime.second;
    value[4] = _getBcdValue(year);
    value[5] = _getBcdValue(month);
    value[6] = _getBcdValue(day);
    value[7] = _getBcdValue(hour);
    value[8] = _getBcdValue(min);
    value[9] = _getBcdValue(second);
  }

  static void _insertDateValueNoH(List<int> value, DateTime ?dateTime) {
    if (dateTime == null) return;
    final int year = dateTime.year;
    final int month = dateTime.month;
    final int day = dateTime.day;
    value[4] = _getBcdValue(year);
    value[5] = _getBcdValue(month);
    value[6] = _getBcdValue(day);
  }

  /// send heart rate package to the watch
  static List<int> sendHeartPackage(
      HealyHeartPackageData healyHeartPackageData) {
    final List<int> value = _generateInitValue();
    final bData = ByteData(8);
    bData.setFloat32(0, healyHeartPackageData.distanceInKm, Endian.little);
    final List<int> distanceValue = bData.buffer.asUint8List(0, 4);
    value[0] = DeviceCmd.heartPackage;
    arrayCopy(distanceValue, 0, value, 1, distanceValue.length);
    value[5] = healyHeartPackageData.speedMinute;
    value[6] = healyHeartPackageData.speedSeconds;
    crcValue(value);
    return value;
  }

  /// set weather
  ///
  ///  Response [SetWeatherResponse]
  static List<int> setWeather(WeatherData weatherData) {
    final List<int> value = generateValue(38);
    value[0] = DeviceCmd.setWeather;
    value[1] = weatherData.weatherId;
    final int tempNow = weatherData.tempNow;
    value[2] = tempNow < 0 ? 1 : 0;
    value[3] = tempNow.abs();
    final int tempLow = weatherData.tempLow;
    value[4] = tempLow < 0 ? 1 : 0;
    value[5] = tempLow.abs();
    final int tempHigh = weatherData.tempHigh;
    value[6] = tempHigh < 0 ? 1 : 0;
    value[7] = tempHigh.abs();
    final String name = weatherData.cityName;
    final List<int> valueName = _getInfoValue(name, 30);
    arrayCopy(valueName, 0, value, 8, valueName.length);
    return value;
  }
}

enum DataRead {
  /// start reading data
  readStart,

  /// continue the last read
  readContinue,

  ///delete data
  delete
}
