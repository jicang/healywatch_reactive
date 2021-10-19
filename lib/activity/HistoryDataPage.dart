// ignore: file_names
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';

import '../LoadingDialog.dart';
import '../button_view.dart';

class HistoryDataPage extends StatefulWidget {
  final String page;

  HistoryDataPage(this.page);

  @override
  State<StatefulWidget> createState() {
    return HistoryDataPageState(page);
  }
}

class HistoryDataPageState extends State<HistoryDataPage> {
  static const PageTotalData = "TotalHistoryData";
  static const PageDetailData = "DetailHistoryData";
  static const PageStaticHrData = "StaticHeartHistoryData";
  static const PageDynamicHrData = "DynamicHeartHistoryData";
  static const PageSleepData = "SleepHistoryData";
  static const PageExerciseData = "ExerciseHistoryData";
  static const PageHrvData = "HrvHistoryData";
  static const PageAllData = "GetAllData";
  String page;

  HistoryDataPageState(this.page);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.page),
      ),
      body: Center(
          child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                ButtonView(
                  "ReadData",
                  action: () => startReadData(),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                ButtonView(
                  "DeleteData",
                  action: () => showDeleteDialog(
                      context, "DeleteData", "Whether DeleteData"),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: list.length == 0 ? getEmptyChild() : getItemList(),
              ),
            ),
          ],
        ),
      )),
    );
  }

  List<Widget> getEmptyChild() {
    List<Widget> list = [];
    list.add(Padding(
      padding: EdgeInsets.all(16),
      child: Container(
        padding: EdgeInsets.all(16),
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "NoData",
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
      ),
    ));
    return list;
  }

  List<Widget> getItemList() {
    return list.map((value) {
      return getItemChild(value);
    }).toList();
  }

  Widget getItemChild(dynamic value) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Container(
        padding: EdgeInsets.all(8),
        color: Colors.blue,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
                child: Text(
              getShowText(value),
              style: TextStyle(color: Colors.white),
            ))
          ],
        ),
      ),
    );
  }

  String getShowText(dynamic historyData) {
    String showText = "";
    switch (page) {
      case PageDetailData:
        showText = getDetailShowText(historyData as HealyDailyEvaluationBlock);
        break;
      case PageTotalData:
        showText = getTotalShowText(historyData as HealyDailyEvaluation);
        break;
      case PageDynamicHrData:
        showText =
            getDynamicShowText(historyData as HealyDailyDynamicHeartRate);
        break;
      case PageStaticHrData:
        showText = getStaticHrShowText(historyData as HealyStaticHeartRate);
        break;
      case PageSleepData:
        showText = getSleepShowText(historyData as HealySleepData);
        break;
      case PageExerciseData:
        showText = getExerciseShowText(historyData as HealyWorkoutData);
        break;
      case PageHrvData:
        showText = getHrvShowText(historyData as HealyEcgSuccessData);
        break;
    }
    return showText;
  }

  String getTotalShowText(HealyDailyEvaluation totalHistoryData) {
    String date = totalHistoryData.date.toString();
    String time = totalHistoryData.workoutDuration.toString();
    String sportTime = totalHistoryData.sportDuration.toString();
    String totalStep = totalHistoryData.totalSteps.toString();
    String distance = totalHistoryData.distanceInKm.toStringAsFixed(2);
    String cal = totalHistoryData.burnedCalories.toStringAsFixed(2);
    String goal = totalHistoryData.goalReachedInPercent.toString();
    String showText = "Date:$date\n"
        "Step:$totalStep\n"
        "Calories:$cal Kcal\n"
        "Distance:$distance Km\n"
        "Goal:$goal%\n"
        "ExerciseTime:$time seconds\n"
        "SportTime:$sportTime minute";
    return showText;
  }

  String getDetailShowText(HealyDailyEvaluationBlock detailHistoryData) {
    String date = detailHistoryData.dateTime.toString();
    String totalStep = detailHistoryData.totalSteps.toString();
    String distance = detailHistoryData.distanceInKm.toStringAsFixed(2);
    String cal = detailHistoryData.burnedCalories.toStringAsFixed(2);
    List<int> stepArray = detailHistoryData.stepsInSegment;
    String showText = "Date:$date\n"
        "Step:$totalStep\n"
        "Calories:$cal Kcal\n"
        "Distance:$distance Km\n"
        "MinterStepArray:$stepArray";

    return showText;
  }

  String getStaticHrShowText(HealyStaticHeartRate staticHrHistoryData) {
    String date = staticHrHistoryData.dateTime.toString();
    int hr = staticHrHistoryData.heartRate;
    String showText = "Date:$date\n"
        "HeartRate:$hr";
    return showText;
  }

  String getDynamicShowText(HealyDailyDynamicHeartRate historyData) {
    String date = historyData.date.toString();
    List<int> hrArray = historyData.heartRatesPerMinute;
    String showText = "Date:$date\n"
        "HeartRateArray:$hrArray";
    return showText;
  }

  String getSleepShowText(HealySleepData sleepHistoryData) {
    String date = sleepHistoryData.startDateTime.toString();
    List<int> quantityArray = sleepHistoryData.sleepQuality;
    String showText = "Date:$date\n"
        "SleepQuantityArray:$quantityArray";
    return showText;
  }

  String getExerciseShowText(HealyWorkoutData exerciseHistoryData) {
    String date = exerciseHistoryData.dateTime.toString();
    int mode = exerciseHistoryData.workoutMode.index;
    int hr = exerciseHistoryData.averageHeartRate;
    int time = exerciseHistoryData.durationTime;
    int steps = exerciseHistoryData.steps;
    int speedSeconds = exerciseHistoryData.speedSeconds;
    String calories = exerciseHistoryData.burnedCalories.toStringAsFixed(2);
    String distance = exerciseHistoryData.distanceInKm.toStringAsFixed(2);
    String showText = "Date:$date\n"
        "ExerciseMode:$mode\n"
        "HeartRate:$hr\n"
        "Steps:$steps\n"
        "Calories:$calories Kcal\n"
        "Distance:$distance Km\n"
        "ExerciseTime:$time seconds\n"
        "PaceSeconds:$speedSeconds seconds";

    return showText;
  }

  String getHrvShowText(HealyEcgSuccessData historyData) {
    String date = historyData.dateTime.toString();
    int hrv = historyData.hrvValue;
    int blood = historyData.bloodValue;
    int heart = historyData.heartRate;
    int tired = historyData.tiredValue;
    int highBloodPressure = historyData.hightBloodPressureValue;
    int lowBloodPressure = historyData.lowBloodPressureValue;
    int moodValue = historyData.moodValue;
    int breathRate = historyData.breathRate;
    String showText = "Date:$date\n"
        "HrvScore:$hrv\n"
        "HeartRate:$heart\n"
        "BreathRate:$breathRate\n"
        "Blood:$blood\n"
        "Tired:$tired\n"
        "HighBloodPressure:$highBloodPressure\n"
        "LowBloodPressure:$lowBloodPressure\n"
        "MoodValue:$moodValue";
    return showText;
  }

  syncFinish() {
    disMiss();
    setState(() {});
  }

  startReadData() async {
    list.clear();
    setState(() {});
    showLoading(context);
    switch (page) {
      case PageDetailData:
        Stream<List<HealyDailyEvaluationBlock>> healySleepData =
            await HealyWatchSDKImplementation.instance
                .getAllDailyEvaluationBlocks();
        healySleepData.listen((event) {
          list.addAll(event);
        }, onDone: () => syncFinish());
        break;
      case PageTotalData:
        Stream<List<HealyDailyEvaluation>> healySleepData =
            await HealyWatchSDKImplementation.instance
                .getDailyEvaluationByDay();
        healySleepData.listen((event) {
          list.addAll(event);
        }, onDone: () => syncFinish());
        break;
      case PageDynamicHrData:
        Stream<List<HealyDailyDynamicHeartRate>> healySleepData =
            await HealyWatchSDKImplementation.instance
                .getAllDynamicHeartRates();
        healySleepData.listen((event) {
          list.addAll(event);
        }, onDone: () => syncFinish());
        break;
      case PageStaticHrData:
        Stream<List<HealyStaticHeartRate>> healySleepData =
            await HealyWatchSDKImplementation.instance.getAllStaticHeartRates();
        healySleepData.listen((event) {
          list.addAll(event);
        }, onDone: () => syncFinish());
        break;
      case PageSleepData:
        Stream<List<HealySleepData>> healySleepData =
            await HealyWatchSDKImplementation.instance.getAllSleepData();
        healySleepData.listen((event) {
          list.addAll(event);
        }, onDone: () => syncFinish());

        break;
      case PageExerciseData:
        Stream<List<HealyWorkoutData>> healyWorkOutDataList =
            await HealyWatchSDKImplementation.instance.getAllWorkoutData();
        healyWorkOutDataList.listen((event) {
          list.addAll(event);
        }, onDone: () => syncFinish());
        break;
      case PageHrvData:
        Stream<List<HealyEcgSuccessData>> healyWorkOutDataList =
            await HealyWatchSDKImplementation.instance.getAllHRVData();
        healyWorkOutDataList.listen((event) {
          list.addAll(event);
        }, onDone: () => syncFinish());
        break;
      case PageAllData:
        Stream<HealyBaseModel> stream =
            HealyWatchSDKImplementation.instance.getAllDataFromWatch();
        stream.listen((event) {
          print(event.toString());
        }).onDone(() {
          syncFinish();
        });
        break;
    }
    // BleManager.instance.writeData(sendValue);
  }

  deleteData() async {
    switch (page) {
      case PageDetailData:
        await HealyWatchSDKImplementation.instance
            .deleteDailyEvaluationBlocks();
        break;
      case PageTotalData:
        await HealyWatchSDKImplementation.instance.deleteAllDailyActivities();
        break;
      case PageDynamicHrData:
        await HealyWatchSDKImplementation.instance.deleteAllDynamicHeartRates();
        break;
      case PageStaticHrData:
        await HealyWatchSDKImplementation.instance.deleteAllStaticHeartRates();
        break;
      case PageSleepData:
        await HealyWatchSDKImplementation.instance.deleteAllSleepData();
        break;
      case PageExerciseData:
        await HealyWatchSDKImplementation.instance.deleteAllWorkoutData();
        break;
      case PageHrvData:
        await HealyWatchSDKImplementation.instance.deleteAllECGData();
        break;
      case PageAllData:
        await HealyWatchSDKImplementation.instance
            .deleteDailyEvaluationBlocks();
        await HealyWatchSDKImplementation.instance.deleteAllDailyActivities();
        await HealyWatchSDKImplementation.instance.deleteAllDynamicHeartRates();
        await HealyWatchSDKImplementation.instance.deleteAllStaticHeartRates();
        await HealyWatchSDKImplementation.instance.deleteAllSleepData();
        await HealyWatchSDKImplementation.instance.deleteAllWorkoutData();
        await HealyWatchSDKImplementation.instance.deleteAllECGData();
        break;
    }
    print("delete");
    startReadData();
  }

  List<dynamic> list = [];

  void showMsgDialog(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getMsgDialog(title, msg);
      },
    );
  }

  Widget getMsgDialog(String dataType, String msg) {
    return new AlertDialog(
      title: Container(
        width: MediaQuery.of(context).size.width,
        child: Text(dataType),
      ),
      content: Text(msg),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Confim"),
        ),
      ],
    );
  }

  void showDeleteDialog(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getDialog(title, msg);
      },
    );
  }

  LoadingDialog? loadingDialog;

  void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        if (loadingDialog == null) {
          return LoadingDialog("Data Synchronizing...");
        } else {
          return loadingDialog!;
        }
      },
    );
  }

  void disMiss() {
    Navigator.of(context).pop(loadingDialog);
  }

  Widget getDialog(String dataType, String msg) {
    return new AlertDialog(
      title: Container(
        width: MediaQuery.of(context).size.width,
        child: Text(dataType),
      ),
      content: Text(msg),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
            deleteData();
          },
          child: Text("Confirm"),
        ),
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
      ],
    );
  }
}
