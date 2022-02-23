import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../model/models.dart';
import 'ble_sdk.dart';

/// Analyze the tool class that returns data from the watch
///
/// ```
///   characteristic.value.listen((value) {
///     if (value.length != 0) ResolveUtil.receiveUpdateValue(value);
///   });
/// ```
///  characteristic is the class that BLE communications uses to send data, which varies depending on the BLE tool used, but the final call is
///  [ResolveUtil.receiveUpdateValue(value)]；
///  the BLE tool used inside the demo is a third-party plugin flutter_blue
///

class ResolveUtil {
  /// date separator
  static const dateSeparate = "/";

  /// bcd code time analysis
  static String _bcd2String(int bytes) {
    final int a = (bytes & 0xf0) >> 4;
    final int b = bytes & 0x0f;
    final String results = "$a$b";
    return results;
  }

  static HealyUserInformation getUserInfo(List<int> value) {
    final List<int> userInfo = List<int>.generate(6, (int index) {
      return 0;
    });
    for (int i = 0; i < 5; i++) {
      userInfo[i] = _hexByte2Int(value[i + 1], 0);
    }
    final StringBuffer stringBuffer = StringBuffer();
    for (int i = 6; i < 12; i++) {
      if (value[i] == 0) continue;
      stringBuffer.write(String.fromCharCode(_hexByte2Int(value[i], 0)));
    }

    return HealyUserInformation(
      gender: userInfo[0] == 0 ? HealyGender.female : HealyGender.male,
      age: userInfo[1],
      heightInCm: userInfo[2].toDouble(),
      weightInKg: userInfo[3].toDouble(),
      stepLength: userInfo[4],
    );
  }

  static HealyDeviceBaseParameter getDeviceInfo(List<int> value) {
    final HealyDeviceBaseParameter deviceBaseParameter =
        HealyDeviceBaseParameter();
    deviceBaseParameter.distanceUnit = _hexByte2Int(value[1], 0) == 1
        ? DistanceUnit.imperial
        : DistanceUnit.metric;
    deviceBaseParameter.hourMode = _hexByte2Int(value[2], 0) == 1
        ? HourMode.hourMode_12
        : HourMode.hourMode_24;
    deviceBaseParameter.wristOnEnable = _hexByte2Int(value[3], 0) == 1;
    deviceBaseParameter.wearingWrist =
        _hexByte2Int(value[4], 0) == 1 ? WearingWrist.left : WearingWrist.right;
    deviceBaseParameter.vibrationLevel = _hexByte2Int(value[5], 0);
    deviceBaseParameter.ancsState = _hexByte2Int(value[6], 0) == 1;
    List<int>low=_getAncsEnableList(value[7]);
    List<int>high=_getAncsEnableList(value[8]);
    List<int>ancsList=BleSdk.generateValue(12);
    BleSdk.arrayCopy(low, 0, ancsList, 0, low.length);
    BleSdk.arrayCopy(high, 0, ancsList, low.length, 4);
    deviceBaseParameter.ancsList=ancsList;
    deviceBaseParameter.baseHeart = _hexByte2Int(value[9], 0);
    deviceBaseParameter.connectVibration = _hexByte2Int(value[10], 0) == 1;
    deviceBaseParameter.brightnessLevel = _hexByte2Int(value[11], 0);
    deviceBaseParameter.sosEnable = _hexByte2Int(value[12], 0) == 1;
    deviceBaseParameter.wristOnSensitivity = _hexByte2Int(value[13], 0);
    deviceBaseParameter.screenOnTime = _hexByte2Int(value[14], 0);
    return deviceBaseParameter;
  }

  static DateTime getDeviceTime(List<int> value) {
    final String dateTimeString = "20"
        "${_bcd2String(value[1])}"
        "$dateSeparate"
        "${_bcd2String(value[2])}"
        "$dateSeparate"
        "${_bcd2String(value[3])} "
        "${_bcd2String(value[4])}:"
        "${_bcd2String(value[5])}:"
        "${_bcd2String(value[6])}";
    final dateFormat = DateFormat('yyyy/MM/dd hh:mm:ss');
    return dateFormat.parse(dateTimeString);
  }

  static List<HealyDailyEvaluation> getTotalHistoryStepData(List<int> value) {
    final List<HealyDailyEvaluation> list = [];
    final int count = _getStepCount(value);
    final int length = value.length;
    final int size = length ~/ count;
    if (size == 0) return list;
    final dateFormat = DateFormat('yyyy/MM/dd');
    for (int i = 0; i < size; i++) {
      final String date = "20${_bcd2String(value[2 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[3 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[4 + i * count])}";
      int step = 0;
      int time = 0;
      double cal = 0;
      double distance = 0;
      for (int j = 0; j < 4; j++) {
        step += _hexByte2Int(value[5 + j + i * count], j);
      }
      for (int j = 0; j < 4; j++) {
        time += _hexByte2Int(value[9 + j + i * count], j);
      }
      for (int j = 0; j < 4; j++) {
        distance += _hexByte2Int(value[13 + j + i * count], j);
      }
      for (int j = 0; j < 4; j++) {
        cal += _hexByte2Int(value[17 + j + i * count], j);
      }
      int exerciseTime = 0;
      final int goal = count == 26
          ? _hexByte2Int(value[21 + i * count], 0)
          : (_hexByte2Int(value[21 + i * count], 0) +
              _hexByte2Int(value[22 + i * count], 1));
      for (int j = 0; j < 4; j++) {
        exerciseTime += _hexByte2Int(value[count - 4 + j + i * count], j);
      }

      final HealyDailyEvaluation healyDailyEvaluation = HealyDailyEvaluation(
        date: dateFormat.parse(date),
        workoutDuration: time,
        sportDuration: exerciseTime,
        totalSteps: step,
        distanceInKm: distance / 100,
        burnedCalories: (cal / 100).floor(),
        goalReachedInPercent: goal,
      );

      list.add(healyDailyEvaluation);
    }
    return list;
  }

  static List<HealyDailyEvaluationBlock> getDetailHistoryData(List<int> value) {
    final List<HealyDailyEvaluationBlock> list = [];
    const count = 25;
    final int length = value.length;
    final int size = length ~/ count;
    if (size == 0) return list;
    final dateFormat = DateFormat('yyyy/MM/dd hh:mm:ss');
    for (int i = 0; i < size; i++) {
      final String date = "20"
          "${_bcd2String(value[3 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[4 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[5 + i * count])} "
          "${_bcd2String(value[6 + i * count])}:"
          "${_bcd2String(value[7 + i * count])}:"
          "${_bcd2String(value[8 + i * count])}";
      int step = 0;
      double cal = 0;
      double distance = 0;
      for (int j = 0; j < 2; j++) {
        step += _hexByte2Int(value[9 + j + i * 25], j);
      }
      for (int j = 0; j < 2; j++) {
        cal += _hexByte2Int(value[11 + j + i * 25], j);
      }
      for (int j = 0; j < 2; j++) {
        distance += _hexByte2Int(value[13 + j + i * 25], j);
      }
      final List<int> stepList = [];
      for (int j = 0; j < 10; j++) {
        final int step = _hexByte2Int(value[15 + j + i * 25], 0);
        stepList.add(step);
      }

      final detailHistoryData = HealyDailyEvaluationBlock(
        dateTime: dateFormat.parse(date),
        totalSteps: step,
        distanceInKm: distance / 100,
        burnedCalories: cal.floor(),
        stepsInSegment: stepList,
      );

      list.add(detailHistoryData);
    }
    return list;
  }

  static List<HealyStaticHeartRate> getStaticHrHistoryData(List<int> value) {
    const int count = 10;
    final int length = value.length;
    final int size = length ~/ count;
    final List<HealyStaticHeartRate> list = [];
    if (size == 0) return list;
    final dateFormat = DateFormat('yyyy/MM/dd hh:mm:ss');
    for (int i = 0; i < size; i++) {
      final String date = "20${_bcd2String(value[3 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[4 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[5 + i * count])} "
          "${_bcd2String(value[6 + i * count])}:"
          "${_bcd2String(value[7 + i * count])}:"
          "${_bcd2String(value[8 + i * count])}";
      final int heart = _hexByte2Int(value[9 + i * 10], 0);

      final HealyStaticHeartRate staticHrHistoryData = HealyStaticHeartRate(
        dateTime: dateFormat.parse(date),
        heartRate: heart,
      );

      list.add(staticHrHistoryData);
    }

    return list;
  }

  static List<HealyDailyDynamicHeartRate> getDynamicHistoryData(
      List<int> value) {
    const int count = 24;
    final int length = value.length;
    final int size = length ~/ count;
    final List<HealyDailyDynamicHeartRate> list = [];
    if (size == 0) return list;
    final dateFormat = DateFormat('yyyy/MM/dd hh:mm:ss');
    for (int i = 0; i < size; i++) {
      final String date = "20${_bcd2String(value[3 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[4 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[5 + i * count])} "
          "${_bcd2String(value[6 + i * count])}:"
          "${_bcd2String(value[7 + i * count])}:"
          "${_bcd2String(value[8 + i * count])}";
      final List<int> hrList = [];
      for (int j = 0; j < 15; j++) {
        final int hr = _hexByte2Int(value[9 + j + i * count], 0);
        hrList.add(hr);
      }

      final HealyDailyDynamicHeartRate dynamicHrData =
          HealyDailyDynamicHeartRate(
        date: dateFormat.parse(date),
        heartRatesPerMinute: hrList,
      );

      list.add(dynamicHrData);
    }

    return list;
  }

  static List<HealySleepData> getSleepHistoryData(List<int> value) {
    const count = 34;
    final int length = value.length;
    final int size = length ~/ count;
    final List<HealySleepData> list = [];
    if (size == 0) return list;
    final dateFormat = DateFormat('yyyy/MM/dd hh:mm:ss');
    for (int i = 0; i < size; i++) {
      final String date = "20${_bcd2String(value[3 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[4 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[5 + i * count])} "
          "${_bcd2String(value[6 + i * count])}:"
          "${_bcd2String(value[7 + i * count])}:"
          "${_bcd2String(value[8 + i * count])}";

      final int sleepLength = _hexByte2Int(value[9 + i * 34], 0);
      final List<int> listQuantity = [];
      for (int j = 0; j < sleepLength; j++) {
        final int sleepQuantity = _hexByte2Int(value[10 + j + i * 34], 0);
        listQuantity.add(sleepQuantity);
      }
      final sleepDate = dateFormat.parse(date);

      final sleepHistoryData = HealySleepData(
        startDateTime: sleepDate,
        sleepQuality: listQuantity,
      );

      list.add(sleepHistoryData);
    }
    return list;
  }

  static List<HealyWorkoutData> getWorkOutData(List<int> value) {
    const int count = 25;
    final int length = value.length;
    final int size = length ~/ count;
    final List<HealyWorkoutData> list = [];
    if (size == 0) return list;
    final dateFormat = DateFormat('yyyy/MM/dd hh:mm:ss');
    for (int i = 0; i < size; i++) {
      final String date = "20${_bcd2String(value[3 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[4 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[5 + i * count])} "
          "${_bcd2String(value[6 + i * count])}:"
          "${_bcd2String(value[7 + i * count])}:"
          "${_bcd2String(value[8 + i * count])}";
      final int mode = _hexByte2Int(value[9 + i * count], 0);
      final int heartRate = _hexByte2Int(value[10 + i * count], 0);
      final int periodTime = _getHighByteData(2, 11 + i * count, value);
      final int steps = _getHighByteData(2, 13 + i * count, value);
      final int speedMin = _hexByte2Int(value[15 + i * count], 0);
      final int speedS = _hexByte2Int(value[16 + i * count], 0);
      final int cal = _getHighByteData(4, 17 + i * count, value);
      final double calD = _intBitToDouble(cal);
      final int distance = _getHighByteData(4, 21 + i * count, value);
      final double distanceD = _intBitToDouble(distance);

      final HealyWorkoutData healyWorkoutData = HealyWorkoutData(
        averageHeartRate: heartRate,
        burnedCalories: calD.floor(),
        dateTime: dateFormat.parse(date),
        distanceInKm: distanceD,
        durationTime: periodTime,
        speedSeconds: speedMin * 60 + speedS,
        steps: steps,
        workoutMode: mode==255?HealyWorkoutMode.autoRun:HealyWorkoutMode.values[mode],
      );

      list.add(healyWorkoutData);
    }

    return list;
  }

/*
* hrv测量历史数据 hrv measurement history data
* */
  static List<HealyEcgSuccessData> getHrvHistoryData(List<int> value) {
    const int count = 17;
    final int length = value.length;
    final int size = length ~/ count;
    final List<HealyEcgSuccessData> list = [];
    if (size == 0) return list;
    final dateFormat = DateFormat('yyyy/MM/dd hh:mm:ss');
    for (int i = 0; i < size; i++) {
      final String date = "20${_bcd2String(value[3 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[4 + i * count])}"
          "$dateSeparate"
          "${_bcd2String(value[5 + i * count])} "
          "${_bcd2String(value[6 + i * count])}:"
          "${_bcd2String(value[7 + i * count])}:"
          "${_bcd2String(value[8 + i * count])}";
      final int hrvValue = _hexByte2Int(value[9 + i * count], 0);
      final int bloodValue = _hexByte2Int(value[10 + i * count], 0);
      final int heartRate = _hexByte2Int(value[11 + i * count], 0);
      final int tiredValue = _hexByte2Int(value[12 + i * count], 0);
      final int highBloodPressureValue = _hexByte2Int(value[13 + i * count], 0);
      final int lowBloodPressureValue = _hexByte2Int(value[14 + i * count], 0);
      final int moodValue = _hexByte2Int(value[15 + i * count], 0);
      final int breathRate = _hexByte2Int(value[16 + i * count], 0);

      final hrvData = HealyEcgSuccessData(
        dateTime: dateFormat.parse(date),
        heartRate: heartRate,
        hrvValue: hrvValue,
        bloodValue: bloodValue,
        tiredValue: tiredValue,
        hightBloodPressureValue: highBloodPressureValue,
        lowBloodPressureValue: lowBloodPressureValue,
        moodValue: moodValue,
        breathRate: breathRate,
      );

      list.add(hrvData);
    }

    return list;
  }

  /*获取高位在后的数据 getting data of highs in the back
  * length 长度 length
  * start 开始的下标位 subscript at the start
  * */
  static int _getHighByteData(int length, int start, List<int> value) {
    int data = 0;
    for (int j = 0; j < length; j++) {
      data += _hexByte2Int(value[j + start], j);
    }
    return data;
  }

  /// floating-point data bytes convert to double
  static double _intBitToDouble(int value) {
    final bData = ByteData(8);
    bData.setInt32(0, value);
    return bData.getFloat32(0, Endian.big);
  }

  static HealySetDeviceTime setTimeSuccessFul(List<int> value) {
    return HealySetDeviceTime(
      isSuccess: true,
      maxLength: _hexByte2Int(value[1], 0),
    );
  }

  static int _hexByte2Int(int b, int count) {
    return (b & 0xff) * pow(256, count) as int;
  }

  static int _getStepCount(List<int> value) {
    int goal = 27;
    final int length = value.length;
    if (length != 2) {
      if (length % 26 == 0) {
        goal = 26;
      } else if (length % 27 == 0) {
        goal = 27;
      } else {
        if ((length - 2) % 26 == 0) {
          goal = 26;
        } else if ((length - 2) % 27 == 0) {
          goal = 27;
        }
      }
    }
    return goal;
  }

  /// real-time step count info
  static HealyRealTimeStep getRealTimeStepData(List<int> value) {
    final DateTime dateTime = DateTime.now();
    int steps = 0;
    double cal = 0;
    double distance = 0;
    int workoutMin = 0;
    int activeMin = 0;
    for (int i = 1; i < 5; i++) {
      steps += _hexByte2Int(value[i], i - 1);
    }
    for (int i = 5; i < 9; i++) {
      cal += _hexByte2Int(value[i], i - 5);
    }
    for (int i = 9; i < 13; i++) {
      distance += _hexByte2Int(value[i], i - 9);
    }
    for (int i = 13; i < 17; i++) {
      workoutMin += _hexByte2Int(value[i], i - 13);
    }
    for (int i = 17; i < 21; i++) {
      if (i < value.length) {
        activeMin += _hexByte2Int(value[i], i - 17);
      }
    }
    final int heartRate = _hexByte2Int(value[21], 0);

    return HealyRealTimeStep(
      dateTime: dateTime,
      steps: steps,
      burnedCalories: (cal / 100).floor(),
      distanceInKm: distance,
      heartRate: heartRate,
      workoutMinutes: workoutMin,
      activeMinutes: activeMin,
    );
  }

  static HealyBaseExerciseData enterWorkOutModeData(List<int> value) {
    HealyBaseExerciseData healyBaseExerciseData;
    final dateFormat = DateFormat('yyyy/MM/dd hh:mm:ss');
    if (value[1] == 1) {
      final String date = "20${_bcd2String(value[2])}"
          "$dateSeparate"
          "${_bcd2String(value[3])}"
          "$dateSeparate"
          "${_bcd2String(value[4])} "
          "${_bcd2String(value[5])}:"
          "${_bcd2String(value[6])}:"
          "${_bcd2String(value[7])}";
      healyBaseExerciseData = HealyEnterExerciseSuccess(dateFormat.parse(date));
    } else {
      final int failedCode = _hexByte2Int(value[2], 0);
      healyBaseExerciseData =
          HealyEnterExerciseFailed(EnterExerciseFailed.values[failedCode]);
    }
    return healyBaseExerciseData;
  }

  static HealyBaseMeasuremenetData ecgResult(List<int> value) {
    HealyBaseMeasuremenetData healyBaseMeasuremenetData;
    if (value[1] == 3) {
      final dateFormat = DateFormat('yyyy/MM/dd hh:mm:ss');
      final String date = "20${_bcd2String(value[10])}"
          "$dateSeparate"
          "${_bcd2String(value[11])}"
          "$dateSeparate"
          "${_bcd2String(value[12])} "
          "${_bcd2String(value[13])}:"
          "${_bcd2String(value[14])}:"
          "${_bcd2String(value[15])}";
      final int hrvValue = _hexByte2Int(value[2], 0);
      final int bloodValue = _hexByte2Int(value[3], 0);
      final int heartRate = _hexByte2Int(value[4], 0);
      final int tiredValue = _hexByte2Int(value[5], 0);
      final int hightBloodPressureValue = _hexByte2Int(value[6], 0);
      final int lowBloodPressureValue = _hexByte2Int(value[7], 0);
      final int moodValue = _hexByte2Int(value[8], 0);
      final int breathRate = _hexByte2Int(value[9], 0);
      healyBaseMeasuremenetData = HealyEcgSuccessData(
        dateTime: dateFormat.parse(date),
        heartRate: heartRate,
        hrvValue: hrvValue,
        bloodValue: bloodValue,
        tiredValue: tiredValue,
        hightBloodPressureValue: hightBloodPressureValue,
        lowBloodPressureValue: lowBloodPressureValue,
        moodValue: moodValue,
        breathRate: breathRate,
      );
    } else if(value[1]==15){
      healyBaseMeasuremenetData=HealyOnlyPPGFinish();
    }else {
      final int failedCode = _hexByte2Int(value[1], 0);
      HealyEcgFailureDataFailedCode healyEcgFailureDataFailedCode;
      if (failedCode == 255) {
        healyEcgFailureDataFailedCode = HealyEcgFailureDataFailedCode.doNotMove;
      } else {
        const List<HealyEcgFailureDataFailedCode> values =
            HealyEcgFailureDataFailedCode.values;
        healyEcgFailureDataFailedCode =
            failedCode < 3 ? values[failedCode] : values[failedCode - 1];
      }
      healyBaseMeasuremenetData =
          HealyEcgFailureData(healyEcgFailureDataFailedCode);
    }
    return healyBaseMeasuremenetData;
  }

  static HealyExerciseData getActivityExerciseData(List<int> value) {
    final int heartRate = _hexByte2Int(value[1], 0);
    int steps = 0;
    double burnedCalories = 0;
    for (int i = 0; i < 4; i++) {
      steps += _hexByte2Int(value[i + 2], i);
    }
    final int valueCal = _getHighByteData(4, 6, value);
    int timeInSeconds = 0;
    for (int i = 0; i < 4; i++) {
      timeInSeconds += _hexByte2Int(value[i + 10], i);
    }
    burnedCalories = _intBitToDouble(valueCal);

    return HealyExerciseData(
      isFinish: value[1]==255,
      steps: steps,
      burnedCalories: burnedCalories.floor(),
      heartRate: heartRate,
      timeInSeconds: timeInSeconds,
    );
  }

  /// Step Target
  static int getGoal(List<int> value) {
    final int goal = _getHighByteData(4, 1, value);
    return goal;
  }

  /// Device battery level
  static int getDeviceBattery(List<int> value) {
    if (value.isEmpty) return 0;

    final int battery = _hexByte2Int(value[1], 0);
    return battery;
  }

  /// Get device MAC address
  static String getDeviceAddress(List<int> value) {
    final StringBuffer address = StringBuffer();
    if (value.isEmpty) return address.toString();

    for (int i = 1; i < 7; i++) {
      final String mac = value[i].toRadixString(16);
      address.write("$mac:");
    }
    final String macAddress = address.toString();
    return macAddress.substring(0, macAddress.lastIndexOf(":"));
  }

  /// Get device version
  static String getDeviceVersion(List<int> value) {
    final StringBuffer stringBuffer = StringBuffer();
    if (value.isEmpty) return stringBuffer.toString();

    for (int i = 1; i < 5; i++) {
      stringBuffer.write(value[i].toRadixString(16) + (i == 4 ? "" : "."));
    }
    return stringBuffer.toString();
  }

  static List<int> _getWeekEnableList(int b) {
    final List<int> array = BleSdk.generateValue(7);
    for (int i = 0; i < 7; i++) {
      array[i] = b & 1;
      // ignore: parameter_assignments
      b = b >> 1;
    }
    return array;
  }

  /// automatic heart rate monitor time interval
  static HealyHeartRateMeasurementSettings getAutoHeart(List<int> value) {
    final int workMode = _hexByte2Int(value[1], 0);
    final String startHour = _bcd2String(value[2]);
    final String startMin = _bcd2String(value[3]);
    final String stopHour = _bcd2String(value[4]);
    final String stopMin = _bcd2String(value[5]);
    final List<int> week = _getWeekEnableList(value[6]);
    final int intervalTime =
        _hexByte2Int(value[7], 0) + _hexByte2Int(value[8], 1);
    HeartRateMeasurementMode heartRateMeasurementMode;
    if (workMode == 0) {
      heartRateMeasurementMode = HeartRateMeasurementMode.off;
    } else if (workMode == 1) {
      heartRateMeasurementMode = HeartRateMeasurementMode.on;
    } else {
      heartRateMeasurementMode = HeartRateMeasurementMode.interval;
    }

    return HealyHeartRateMeasurementSettings(
      measurementMode: heartRateMeasurementMode,
      startHour: int.parse(startHour),
      startMinute: int.parse(startMin),
      endHour: int.parse(stopHour),
      endMinute: int.parse(stopMin),
      intervalTime: intervalTime,
      daysInWeek: week,
    );
  }

  /// Get sedentary reminder
  static HealySedentaryReminderSettings getActivityAlarm(List<int> value) {
    final String startHour = _bcd2String(value[1]);
    final String startMin = _bcd2String(value[2]);
    final String stopHour = _bcd2String(value[3]);
    final String stopMin = _bcd2String(value[4]);
    final int time = _hexByte2Int(value[6], 0);
    final int step = _hexByte2Int(value[7], 0);
    final bool enable = _hexByte2Int(value[8], 0) == 1;
    return HealySedentaryReminderSettings(
      startHour: int.parse(startHour),
      startMinute: int.parse(startMin),
      endHour: int.parse(stopHour),
      endMinute: int.parse(stopMin),
      interval: time,
      minimumStepsGoal: step,
      isEnabled: enable,
      daysInWeek: _getWeekEnableList(value[5]),
    );
  }

  /// Get workout reminder
  static HealyWorkoutReminderSettings getWorkOutReminder(List<int> value) {
    final String startHour = _bcd2String(value[1]);
    final String startMin = _bcd2String(value[2]);
    final int days = _hexByte2Int(value[3], 0);
    final bool enable = _hexByte2Int(value[5], 0) == 1;
    final int time = _hexByte2Int(value[6], 0) + _hexByte2Int(value[7], 1);
    final HealyWorkoutReminderSettings healyWorkoutReminderSettings =
        HealyWorkoutReminderSettings(
      hour: int.parse(startHour),
      minute: int.parse(startMin),
      daysInWeek: _getWeekEnableList(value[4]),
      duration: time,
      isEnabled: enable,
      days: days,
    );

    return healyWorkoutReminderSettings;
  }

  static HealySleepModeData getSleepModeData(List<int> value) {
    final String startHour = _bcd2String(value[1]);
    final String startMin = _bcd2String(value[2]);
    final String endHour = _bcd2String(value[3]);
    final String endMin = _bcd2String(value[4]);
    final bool enable = _hexByte2Int(value[5], 0) == 1;
    final HealySleepModeData healySleepModeData = HealySleepModeData(
      startHour: int.parse(startHour),
      startMin: int.parse(startMin),
      endHour: int.parse(endHour),
      endMin: int.parse(endMin),
      isEnabled: enable,
    );

    return healySleepModeData;
  }

  /// Get alarm data
  static List<HealyClock> getClockData(List<int> value) {
    final List<HealyClock> list = [];
    const count = 41;
    final int length = value.length;
    final int size = length ~/ count;
    if (size == 0) return list;
    for (int i = 0; i < size; i++) {
      final HealyClock clock = HealyClock();
      final int id = _hexByte2Int(value[4 + i * count], 0);
      final int enable = _hexByte2Int(value[5 + i * count], 0);
      final int type = _hexByte2Int(value[6 + i * count], 0);
      final String hour = _bcd2String(value[7 + i * count]);
      final String min = _bcd2String(value[8 + i * count]);
      int lengthS = _hexByte2Int(value[10 + i * count], 0);
      if (lengthS > 30) lengthS = 30;
      final List<int> contentList = BleSdk.generateValue(lengthS);
      for (int J = 0; J < lengthS; J++) {
        contentList[J] = value[11 + J + i * count];
      }
      final String content = utf8.decode(contentList);
      clock.id = id;
      clock.enable = enable == 1;
      clock.content = content;
      clock.hour = int.parse(hour);
      clock.minute = int.parse(min);
      clock.healyClockMode = HealyClockMode.values[type];
      clock.weekEnableList = _getWeekEnableList(value[9 + i * count]);
      list.add(clock);
    }
    return list;
  }

  static HealyWorkoutType getWorkOutType(List<int> value) {
    final int length = _hexByte2Int(value[1], 0);
    final List<HealyWorkoutMode> selectedList = List.generate(length, (index) => HealyWorkoutMode.running);
    List<HealyWorkoutMode> modeList=HealyWorkoutMode.values;;
    for (int i = 0; i < length; i++) {
       int selected = _hexByte2Int(value[i + 2], 0);

       print(selected);
      selectedList[i] = modeList[selected];

    }

    return HealyWorkoutType(selectedList);
  }

  static HealyWatchFaceStyle getWatchFaceStyle(List<int> value) {
    if (value.isEmpty) {
      return HealyWatchFaceStyle(
          HealyDeviceBaseParameter.defaultWatchFaceStyle);
    }

    final int style = _hexByte2Int(value[1], 0);
    return HealyWatchFaceStyle(style);
  }

  static String getSerialNumber(List<int> value) {
    final StringBuffer serialNumber = StringBuffer();
    if (value.isEmpty) return serialNumber.toString();

    final int mode = _hexByte2Int(value[1], 0);
    if (mode == 0) {
      // early shipments (1.7K) didn't go through the serial number setting procedure in production, so there is no valid serial number AA, fixed at 0, BB~FF is the MAC address
      for (int i = 2; i < 8; i++) {
        serialNumber.write(value[i].toRadixString(16) + (i == 7 ? "" : "."));
      }
    } else {
      for (int i = 1; i < 6; i++) {
        serialNumber.write(value[i].toRadixString(16) + (i == 5 ? "" : "."));
      }
    }

    return serialNumber.toString();
  }

  static bool setWorkOutReminder(List<int> value) {
    return _hexByte2Int(value[1], 0) == 0;
  }

  static HealyFunction function(List<int> value) {
    HealyFunction healyFunction = HealyFunction.rejectTel;
    if (value[1] == 2) healyFunction = HealyFunction.camera;
    if (value[1] == 4) healyFunction = HealyFunction.findPhone;
    if (value[1] == 1 && value[2] == 0) healyFunction = HealyFunction.rejectTel;
    if (value[1] == 1 && value[2] == 1) healyFunction = HealyFunction.tel;
    if (value[1] == 3 && value[2] == 1) {
      healyFunction = HealyFunction.musicControlPre;
    }
    if (value[1] == 3 && value[2] == 3) {
      healyFunction = HealyFunction.musicControlNext;
    }
    if (value[1] == 3 && value[2] == 4) {
      healyFunction = HealyFunction.musicControlPlay;
    }
    if (value[1] == 3 && value[2] == 5) {
      healyFunction = HealyFunction.musicControlPause;
    }
    return healyFunction;
  }

  static HealyECGData ecgMeasureData(List<int> value) {
    final List<int> ecgList = [];
    final int length = value.length ~/ 2;
    for (int i = 0; i < length - 1; i++) {
      int ecgValue =
          _hexByte2Int(value[i * 2 + 1], 1) + _hexByte2Int(value[i * 2 + 2], 0);
      if (ecgValue >= 32768) ecgValue = ecgValue - 65536;
      ecgList.add(ecgValue);
    }
    return HealyECGData(
      values: ecgList,
      dateTime: DateTime.now(),
    );
  }

  static HealyPPGData ppgMeasureData(List<int> value) {
    final List<int> ppgList = [];
    final int length = value.length ~/ 2;
    for (int i = 0; i < length - 1; i++) {
      int ppgValue =
          _hexByte2Int(value[i * 2 + 1], 1) + _hexByte2Int(value[i * 2 + 2], 0);
      if (ppgValue >= 32768) ppgValue = ppgValue - 65536;
      ppgList.add(ppgValue);
    }
    return HealyPPGData(
      values: ppgList,
      dateTime: DateTime.now(),
    );
  }

  static HealyECGQualityData ecgQuality(List<int> value) {
    final int heartRate = _hexByte2Int(value[1], 0);
    final int hrv = _hexByte2Int(value[2], 0);
    final int ecgQuantity = _hexByte2Int(value[3], 0);
    return HealyECGQualityData(
      hrvValue: hrv,
      heartRate: heartRate,
      ecgQuantity: ecgQuantity,
      dateTime: DateTime.now(),
    );
  }
  static HealyResUpdateData getHealyResUpdate(List<int> value){
    int updateIndex=_hexByte2Int(value[3], 0);
    bool needUpdate=value[1] == 1 && value[2] == 1;
    return HealyResUpdateData(needUpdate: needUpdate, updateIndex: updateIndex);
  }

  static List<int> _getAncsEnableList(int b) {
    final List<int> array = BleSdk.generateValue(8);
    for (int i = 0; i < 8; i++) {
      array[i] = b>>i & 1;
      // ignore: parameter_assignments

    }
    return array;
  }
}
