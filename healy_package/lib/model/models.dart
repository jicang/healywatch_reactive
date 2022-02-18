import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Abstract class which all models need to inherit from
abstract class HealyBaseModel {}

/// This heart rate is messured while entering workout mode or
/// manual messurement by user by an date
///
/// The heartRatesPerMinute are the full list of heart rates, there
/// no blocks of 15 items.
///
/// The heart rate data are combined of the 15 min blocks of Healy Watch.
///
/// [date] The date model for an day
/// [heartRatesPerMinute] The hole list of heart rates
class HealyDailyDynamicHeartRate extends HealyBaseModel {
  final DateTime date;
  final List<int> heartRatesPerMinute;

  HealyDailyDynamicHeartRate({
    required this.date,
    required this.heartRatesPerMinute,
  });
}

/// Represents the activities done in one by hole time.
/// There is no blocks of 10 minutes. The data are combined
/// of Healy Watch Data.
///
///
/// [date] (year, month, day, no time)
/// [workoutDuration] 运动时间（单位秒）
/// [sportDuration] 快速运动时间（单位分钟）
/// [totalSteps] alls steps made on this day
/// [distanceInKm] walked/driven on this day
/// [burnedCalories] burned calories on this day
/// [goalReachedInPercent] goal reached on this day in percent
class HealyDailyEvaluation extends HealyBaseModel {
  final DateTime date;
  final int workoutDuration;
  final int sportDuration;
  final int totalSteps;
  final double distanceInKm;
  final int burnedCalories;
  final int goalReachedInPercent;

  HealyDailyEvaluation({
    required this.date,
    required this.workoutDuration,
    required this.sportDuration,
    required this.totalSteps,
    required this.distanceInKm,
    required this.burnedCalories,
    required this.goalReachedInPercent,
  });
}

/// Represents the activities done in one 10 minute segment
///
/// [dateTime] date time of
/// [totalSteps] alls steps made this segment
/// [distanceInKm] walked/driven this day
/// [burnedCalories] this day
/// [stepsInSegment] each entry is number of steps for this minute
class HealyDailyEvaluationBlock extends HealyBaseModel {
  final DateTime dateTime;
  final int totalSteps;
  final double distanceInKm;
  final int burnedCalories;
  final List<int> stepsInSegment;

  HealyDailyEvaluationBlock({
    required this.dateTime,
    required this.totalSteps,
    required this.distanceInKm,
    required this.burnedCalories,
    required this.stepsInSegment,
  });
}

/// Abstract class for
abstract class HealyBaseMeasuremenetData extends HealyBaseModel {}

class HealyEnterEcgData extends HealyBaseMeasuremenetData {
  final EnterEcgResultCode ecgResultCode;

  HealyEnterEcgData({
    required this.ecgResultCode,
  });
}

class HealyOnlyPPGFinish extends HealyBaseMeasuremenetData {}

enum EnterEcgResultCode {
  //success 成功
  success,
  //already in ecg mode 已经处于该模式
  alreadyEnter,
  //can not open because it's in work out mode 当前处于运动模式而无法打开。
  workOutMode,
  //can not open because it's in battery charging mode 当前处于充电界面而无法打开。
  chargeMode,
  //can not open because it's in sos mode 当前处于SOS模式而无法打开。
  sosMode,
  //can not open because it's in UI upgrade mode 当前在UI升级模式而无法打开。
  resUpdateMode
}

/// Model class for ECG data
///
/// [vaue] ecg measurement data set
class HealyECGData extends HealyBaseMeasuremenetData {
  final List<int> values;
  final DateTime dateTime;

  HealyECGData({
    required this.values,
    required this.dateTime,
  });
}

/// Model class for PPG data
///
/// [vaue] ppg measurement data set
class HealyPPGData extends HealyBaseMeasuremenetData {
  final List<int> values;
  final DateTime dateTime;

  HealyPPGData({
    required this.values,
    required this.dateTime,
  });
}

/// Model class for ECG quality data set
///
/// [hrvValue] hrv value (min/max value)
/// [heartRate] heart rate value
/// [ecgQuantity] value of ECG quantity
class HealyECGQualityData extends HealyBaseMeasuremenetData {
  final int hrvValue;
  final int heartRate;
  final int ecgQuantity;
  final DateTime dateTime;

  HealyECGQualityData({
    required this.hrvValue,
    required this.heartRate,
    required this.ecgQuantity,
    required this.dateTime,
  });
}

/// Model class of ecg data.
///
/// [dateTime] date time of model
/// [heartRate] heart rate value
/// [hrvValue] hrv value (min/max value)
/// [bloodValue] blood value (min/max value)
/// [tiredValue] tired value (min/max value)
/// [hightBloodPressureValue] high blood pressure value (min/max value)
/// [lowBloodPressureValue] low blood pressure value (min/max value)
/// [moodValue] mood value (min/max value)
/// [breathRate] breath value (min/max value)
class HealyEcgSuccessData extends HealyBaseMeasuremenetData {
  final DateTime dateTime;
  final int heartRate;
  final int hrvValue;
  final int bloodValue;
  final int tiredValue;
  final int hightBloodPressureValue;
  final int lowBloodPressureValue;
  final int moodValue;
  final int breathRate;

  List<HealyECGQualityData> qualityPoints = [];
  List<HealyPPGData> ppgData = [];
  List<HealyECGData> ecgData = [];

  HealyEcgSuccessData({
    required this.dateTime,
    required this.heartRate,
    required this.hrvValue,
    required this.bloodValue,
    required this.tiredValue,
    required this.hightBloodPressureValue,
    required this.lowBloodPressureValue,
    required this.moodValue,
    required this.breathRate,
  });
}

/// Model class of failure ecg measurement.
///
/// [errorCode] error code of failure ECG measurement
class HealyEcgFailureData extends HealyBaseMeasuremenetData {
  final HealyEcgFailureDataFailedCode errorCode;

  HealyEcgFailureData(this.errorCode);
}

enum HealyEcgFailureDataFailedCode {
  measurementNotTurned,
//measurement in progress 测量进行中
  measurementInProgress,
  //measurement timeout, automatically closed 测量超时，已经自动关闭
  measurementTimeout,
  //measurement closed because of low battery 因为低电关闭
  lowPower,
  //measurement closed because of battery charging 因为充电关闭
  charge,
  //measurement closed because of the user manually / or App command closing it 用户手动/App指令提前关闭
  manualClose,
  //measurement closed because of it's restoring to factory mode 因为用于恢复出厂设置而关闭.
  restoreFactory,
  //measurement closed because of entering work out mode 因为进入运动模式而关闭
  workOutMode,
  //measurement closed because of entering sos mode 因为进入SOS模式关闭
  sosMode,
  //measurement closed automatically because of weak signal ECG信号弱自动退出检测
  weakSignal,
  //lead connection shedding 导联脱落
  leadShedding,
  //lead connecting 导联连接
  leadConnection,
  //do not move reminder during measurement 提示测量中请不要动
  doNotMove,
}

abstract class HealyBaseExerciseData {}

/// Represents data model while start exercise mode
///
/// [steps] number of steps
/// [burnedCalories] current burned calories
/// [heartRate] current heart rate
/// [timeInSeconds] elapsed time in seconds
class HealyExerciseData extends HealyBaseExerciseData {
  final int steps;
  final int burnedCalories;
  final int heartRate;
  final int timeInSeconds;

  HealyExerciseData({
    required this.steps,
    required this.burnedCalories,
    required this.heartRate,
    required this.timeInSeconds,
  });
}

class HealyEnterExerciseSuccess extends HealyBaseExerciseData {
  final DateTime dateTime;

  HealyEnterExerciseSuccess(this.dateTime);
}

class HealyEnterExerciseFailed extends HealyBaseExerciseData {
  EnterExerciseFailed enterExerciseFailedCode;

  HealyEnterExerciseFailed(this.enterExerciseFailedCode);
}

enum EnterExerciseFailed {
  none,
  //already in work out mode 当前已经处于运动模式状态
  alreadyEnter,
  //now in ecg and ppg mode 当前处于ECG和PPG状态
  ecgPPGMode,
  //the entered work out mode is undefined 打开的运动类型未定义
  undefined,
  //now in sos emergency mode 当前处于SOS紧急状态
  sosMode,
  //now in battery charging mode 当前处于充电状态
  chargeMode,
  //now in UI upgrade mode 当前在UI升级模式
  resUpdateMode,
  //the work out mode now was not selected 当前运动类型没有选择
  modeNotChoose
}

/// Model of watch settings for heart rate measurment.
///
/// [measurementMode] mode of measurement
/// [startHour] start hour of measurement in 24h mode 1-24
/// [startMinute] start minute of measurement 0-60
/// [endHour] end hour of measurement in 24h mode 1-24
/// [endMinute] end minute of measurement 0-60
/// [intervalTime] intervall between measurements in seconds
/// [daysInWeek] active days in week, dirst digit is sunday [1,1,1,1,0,0,0], 1= enabled, 0 not enabled
class HealyHeartRateMeasurementSettings extends HealyBaseModel {
  final HeartRateMeasurementMode measurementMode;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int intervalTime;
  final List<int> daysInWeek;

  HealyHeartRateMeasurementSettings({
    required this.measurementMode,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.intervalTime,
    required this.daysInWeek,
  });
}

enum HeartRateMeasurementMode {
  off,
  on, // messures whole time period
  interval, // messures in intervals at time period
}

/// Settings model for sedentary reminder.
///
/// [startHour] start hour 0-24
/// [startMinute] start minute 0-60
/// [endHour] end hour 0-60
/// [endMinute] end minute 0-60
/// [interval] interval between measurements
/// [minimumStepsGoal] minimum number of steps as goal
/// [isEnabled] value if sedentary reminder is enabled
/// [daysInWeek] active days in week, dirst digit is sunday [1,1,1,1,0,0,0], 1= enabled, 0 not enabled
class HealySedentaryReminderSettings extends HealyBaseModel {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int interval;
  final int minimumStepsGoal;
  final bool isEnabled;
  final List<int> daysInWeek;

  HealySedentaryReminderSettings({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.interval,
    required this.minimumStepsGoal,
    required this.isEnabled,
    required this.daysInWeek,
  });
}

/// Model of sleep data of one night.
/// Important: The data are combined, there
/// are no blocks of 24 elements.
///
/// [startDateTime] start date time of sleep
///
/// [sleepQuality] list with quality items of the hole sleep in 5 min steps (clear min/ max value)
class HealySleepData extends HealyBaseModel {
  final DateTime startDateTime;
  final List<int> sleepQuality;

  HealySleepData({
    required this.startDateTime,
    required this.sleepQuality,
  });
}

/// Model class of static heart rate
///
/// [dateTime] date time of model
/// [heartRate] value of heart rate (min/ max unclear)
class HealyStaticHeartRate extends HealyBaseModel {
  final DateTime dateTime;
  final int heartRate;

  HealyStaticHeartRate({
    required this.dateTime,
    required this.heartRate,
  });
}

/// Model class for user information
///
/// [gender] gender of user (male/ female)
/// [age] age of user 10-99
/// [heightInCm] the height of the user in cm 100-280
/// [weightInKg] the weight of the user in kg 10-250
/// [stepLength] the length of step
class HealyUserInformation extends HealyBaseModel {
  final HealyGender gender;
  final int age;
  final double heightInCm;
  final double weightInKg;
  final int stepLength;

  HealyUserInformation({
    required this.gender,
    required this.age,
    required this.heightInCm,
    required this.weightInKg,
    required this.stepLength,
  });
}

enum HealyGender {
  female,
  male,
  neutrum,
}

/// Model class of face style
///

/// [imageId] the id or index of image
class HealyWatchFaceStyle extends HealyBaseModel {
  final int imageId;

  HealyWatchFaceStyle(
    this.imageId,
  );
}

/// Model of exercise detail data. The data are
/// combined data of the [DetailHistoryData]. This means
/// the steps are combined.
///
///
/// [dateTime] start date time of workout
/// [workoutMode] type of workout
/// [averageHeartRate] average heart rate
/// [steps] the number of steps in this workout
/// [speedSeconds] the speed/pace of user per second
/// [burnedCalories] the number of burned calories
/// [distanceInKm] the distance of workout
class HealyWorkoutData extends HealyBaseModel {
  final DateTime dateTime;
  final HealyWorkoutMode workoutMode;
  final int durationTime;
  final int averageHeartRate;
  final int steps;
  final int speedSeconds;
  final int burnedCalories;
  final double distanceInKm;

  HealyWorkoutData({
    required this.dateTime,
    required this.workoutMode,
    required this.durationTime,
    required this.averageHeartRate,
    required this.steps,
    required this.speedSeconds,
    required this.burnedCalories,
    required this.distanceInKm,
  });
}

enum HealyWorkoutMode {
  running,
  cycling,
  badminton,
  soccer,
  tennis,
  yoga,
  breathing,
  dancing,
  basketball,
  hiking,
  fitness,
  autoRun
}

/// Model class for workout reminder
///
/// [hour] hour to start with reminder
/// [minute] minute of hour when get reminder
/// [daysInWeek] active days in week, dirst digit is sunday
/// [days] the number of workouts in the week
/// [duration] the duration of workout in minutes
/// [isEnabled] value if reminder is enabled (true/ false)
class HealyWorkoutReminderSettings extends HealyBaseModel {
  final int hour;
  final int minute;
  final List<int> daysInWeek;
  final int days;
  final int duration;
  final bool isEnabled;

  HealyWorkoutReminderSettings({
    required this.hour,
    required this.minute,
    required this.daysInWeek,
    required this.duration,
    required this.isEnabled,
    required this.days,
  });
}

/// Model class for workout type
///
/// [name] name of workout type
/// [isSelected] value if workout type is selected
class HealyWorkoutType extends HealyBaseModel {
  List<int> selectedList;

  HealyWorkoutType(
    this.selectedList,
  );
}

class HealySetDeviceTime extends HealyBaseModel {
  bool isSuccess;
  int maxLength;

  HealySetDeviceTime({required this.isSuccess, required this.maxLength});
}

/// Setting watch parameters
///
/// call when you need to set multiple properties at once;
/// parameters can also be set separately
class HealyDeviceBaseParameter extends HealyBaseModel {
  /// default watch face
  ///
  /// these defaults are the default values defined on the healy watch
  static const int defaultWatchFaceStyle = 0;

  /// default wear on left hand (1+128)
  static const int defaultWearingWrist = 1;

  /// default wrist-on sensitivity (medium)(2+128)
  static const int defaultWristOnSensitivity = 2;

  /// default screen brightness level (9+128)
  static const int defaultBrightnessLevel = 9;

  /// default screen-on time (4+128)
  static const int defaultScreenOnTime = 4;

  /// default vibration intensity（medium）(3+128)
  static const int defaultVibrationLevel = 3;

  /// distance unit
  ///
  /// can be called and set individually [BleSdk.setDistanceUnit]
  DistanceUnit? distanceUnit;

  /// hour mode (12h/24h)
  ///
  /// can be called and set individually [BleSdk.setTimeModeUnit]设置
  HourMode? hourMode;

  /// default wearing wrist (left/right wrist)
  ///
  /// can be called and set individually [BleSdk.setWearingWrist(wearingWrist)]设置
  WearingWrist? wearingWrist;

  /// enable wrist-on function
  ///
  /// can be called and set individually [BleSdk.enableWristOn(enable)]设置
  bool? wristOnEnable;

  /// display enablement of sos interface on the watch
  ///
  /// can be called and set individually [BleSdk.setSosEnable(enable)]设置
  bool? sosEnable;

  /// connection vibration
  ///
  /// [BleSdk.setConnectVibration(enable)]设置
  bool? connectVibration;

  /// ancs enablement
  ///
  /// can be called and set individually [BleSdk.enableAncs()],[BleSdk.disableAncs()] 设置
  bool ancsState = false;

  /// wrist-on sensitivity
  ///
  /// can be called and set individually [BleSdk.setWristOnSensitivity(sensitivity)]设置
  int? wristOnSensitivity;

  /// screen-on time
  ///
  /// can be called and set individually [BleSdk.setScreenOnTime(screenOnTime)]设置
  int? screenOnTime;

  /// vibration intensity
  ///
  /// can be called and set individually [BleSdk.setVibrationLevel(level)]设置
  int? vibrationLevel;

  /// basic heart rate
  ///
  /// can be called and set individually [BleSdk.setBaseHeartRate(hr)]设置
  int? baseHeart;

  /// brightness level
  ///
  /// can be called and set individually [BleSdk.setBrightnessLevel(level)]设置
  int? brightnessLevel;
}

class WeatherData extends HealyBaseModel {
  /// current temperature (Celsius)
  int tempNow;

  /// highest temperature of the day (Celsius)
  int tempHigh;

  /// lowest temperature of the day (Celsius)
  int tempLow;

  /// city name
  String cityName = "";

  /// weather ID (0~38 or 99)
  ///
  /// reference [https://docs.seniverse.com/api/start/code.html]
  int weatherId;

  WeatherData(
      {required this.cityName,
      required this.weatherId,
      required this.tempNow,
      required this.tempHigh,
      required this.tempLow});
}

/// real-time step count
class HealyRealTimeStep extends HealyBaseModel {
  final DateTime dateTime;

  final int steps;

  /// calories(e.g: 0.22 kcal)
  final int burnedCalories;

  /// distance(e.g: 0.02km)
  final double distanceInKm;

  final int heartRate;

  /// work out min
  final int workoutMinutes;

  /// active min;
  final int activeMinutes;

  HealyRealTimeStep({
    required this.dateTime,
    required this.steps,
    required this.burnedCalories,
    required this.distanceInKm,
    required this.heartRate,
    required this.workoutMinutes,
    required this.activeMinutes,
  });
}

/// alarm
class HealyClock extends HealyBaseModel {
  /// alarm ID (this ID is meaningless while setting,
  /// the firmware will delete the previous alarm and add
  /// new ones according to the app's transmitted information)
  int id = 0;

  /// alarm type
  HealyClockMode healyClockMode = HealyClockMode.none;

  /// hour of start of alarm
  int hour = 7;

  /// minute of start of alarm
  int minute = 0;

  /// alarm content（healy watch doesn't use this, can be skipped）
  String content = "";

  /// alarm turn on /off
  bool enable = false;

  ///  weekly enablement，[1,1,1,1,0,0,0]（1 as enable, 0 as close, first digit is Sunday）
  List<int> weekEnableList = [];
}

class HealyHeartPackageData extends HealyBaseModel {
  final double distanceInKm;
  final int speedMinute;
  final int speedSeconds;

  HealyHeartPackageData({
    required this.distanceInKm,
    required this.speedMinute,
    required this.speedSeconds,
  });
}

class HealyBreathingSession extends HealyBaseExerciseData {
  final int level;
  final int durationInSeconds;

  HealyBreathingSession({
    required this.level,
    required this.durationInSeconds,
  });
}

/// Notification reminder
///
/// Only needed in Android, you need the permission to read the notification bar;
/// after reading the notification bar, you can determine the type of notification
/// you want to send according to the notification package name
/// SMS message and phone reminders require phone and SMS permissions
class HealyNotifier {
  /// notification type
  HealyNotifierMode healyNotifierMode;

  /// notification content
  String info;

  /// notification info
  String title;

  HealyNotifier({
    required this.healyNotifierMode,
    required this.info,
    required this.title,
  });
}

enum HealyNotifierMode {
  dataTel,
  dataSms,
  dataWeChat,
  dataFacebook,
  dataINSTAGRAM,
  dataSkype,
  dataTelegra,
  dataTwitter,
  dataVk,
  dataWhatApp,
  dataOther,
  dataEmail,
  dataLine,
  dataStopTel
}

enum HealyClockMode {
  none,
  ordinary,
  pillReminder,
  healyDay,
  healyNight,
}

enum DistanceUnit {
  metric,
  imperial,
}

enum HourMode {
  hourMode_12,
  hourMode_24,
}

enum WearingWrist {
  left,
  right,
}

enum HealyFunction {
  camera,
  findPhone,
  rejectTel,
  tel,
  musicControlPre,
  musicControlNext,
  musicControlPlay,
  musicControlPause
}

class HealySleepModeData {
  bool isEnabled;
  int startHour;
  int startMin;
  int endHour;
  int endMin;

  HealySleepModeData(
      {required this.isEnabled,
      required this.startHour,
      required this.startMin,
      required this.endHour,
      required this.endMin});
}

class HealyResUpdateData {
  bool needUpdate;
  int updateIndex;

  HealyResUpdateData({required this.needUpdate, required this.updateIndex});
}

/// In this model the sleep data is cobined. This means
/// that this model represent an whole sleep, with all included
/// data of sleep quality and heart rate.
class HealyCombinedSleepData {
  DateTime startDateTime;
  DateTime? endDateTime;
  List<int> sleepQuality = [];
  List<int> heartRate = [];

  HealyCombinedSleepData({required this.startDateTime});
}

class HealyDevice {
  final String id;
  final String name;

  HealyDevice({
    required this.id,
    required this.name,
  });

  HealyDevice.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  @override
  String toString() {
    return 'id: $id name: $name';
  }

  factory HealyDevice.fromDiscorveredDevice(DiscoveredDevice device) {
    return HealyDevice(
      id: device.id,
      name: device.name,
    );
  }
}
