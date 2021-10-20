import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';
import 'package:provider/provider.dart';

import '../button_view.dart';

class ExercisePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ExercisePageState();
  }
}

class ExercisePageState extends State<ExercisePage> {
  bool enterCamera = false;
  HealyWorkoutMode notifyType = HealyWorkoutMode.running;
  String title = "";
  String info = "";
  List<String> list = [
    "Running",
    "Cycling",
    "Badminton",
    "Football",
    "Tennis",
    "Yoga",
    "Breath",
    "Dancing",
    "Basketball",
    "Hiking",
    "Gym",
  ];
  TextEditingController _titleController = TextEditingController();
  TextEditingController _infoController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    cancelTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Exercise"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              childAspectRatio: 3.5,
              children: list.map((value) {
                return RadioListTile(
                  title: Text(value),
                  value: HealyWorkoutMode.values[list.indexOf(value)],
                  groupValue: notifyType,
                  onChanged: (HealyWorkoutMode? value) => sendNotify(value),
                );
              }).toList(),
            ),
          ),
          Column(
            children: <Widget>[
              TextField(
                decoration: InputDecoration(labelText: "Breath Level"),
                textAlign: TextAlign.center,
                controller: _titleController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              TextField(
                decoration: InputDecoration(labelText: "Breath Duration"),
                textAlign: TextAlign.center,
                controller: _infoController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.topCenter,
              height: 100,
              child: Row(
                children: <Widget>[
                  ButtonView(
                    "EnterExercise",
                    action: () => enableExercise(true),
                  ),
                  ButtonView("StopExercise",
                      action: () => enableExercise(false))
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(info),
          )
        ],
      ),
    );
  }

  sendNotify(HealyWorkoutMode? value) {
    notifyType = value!;
    setState(() {});
  }

  bool isEmpty(String value) {
    return value.length == 0;
  }

  StreamSubscription<HealyBaseExerciseData>? healyExerciseDataSubscription;

  enableExercise(bool enable) async {
    healyExerciseDataSubscription?.cancel();
    if (notifyType == HealyWorkoutMode.breathing) {
      String levelString = _titleController.text;
      String durationString = _infoController.text;
      if (levelString.isEmpty || durationString.isEmpty) return;
      if (enable) {
        Stream<HealyBaseExerciseData> healyExerciseDataStream =
            HealyWatchSDKImplementation.instance.startBreathingSession(
                HealyBreathingSession(
                    level: int.parse(levelString),
                    durationInSeconds: int.parse(durationString)));
        showExerciseData(healyExerciseDataStream);
      } else {
        bool isSuccess =
            await HealyWatchSDKImplementation.instance.stopBreathingSession();
        if (isSuccess) {
          showMsgDialog(context, "isExit", "");
        }
      }
    } else {
      if (enable) {
        Stream<HealyBaseExerciseData> healyExerciseDataStream =
            await HealyWatchSDKImplementation.instance.startWorkout(notifyType);
        showExerciseData(healyExerciseDataStream);
      } else {
        bool isSuccess =
            await HealyWatchSDKImplementation.instance.stopWorkout();
        if (isSuccess) {
          cancelTimer();
          showMsgDialog(context, "isExit", "");
        }
      }
    }
  }

  showExerciseData(Stream<HealyBaseExerciseData> healyExerciseDataStream) {
    healyExerciseDataSubscription = healyExerciseDataStream.listen((event) {
      if (event is HealyExerciseData) {
        startTimer();
        var heartRate = event.heartRate;
        var step = event.steps;
        var cal = event.burnedCalories;
        var time = event.timeInSeconds;
        info = "Step: $step\n"
            "Calories: $cal KCAL\n"
            "HeartRate: $heartRate bpm\n"
            "ExerciseTime: $time second";
        if (mounted) setState(() {});
      } else if (event is HealyEnterExerciseSuccess) {
        showMsgDialog(context, "isEnterSuccess", "");
      } else if (event is HealyEnterExerciseFailed) {
        cancelTimer();
        EnterExerciseFailed enterExerciseFailedCode =
            event.enterExerciseFailedCode;
        showMsgDialog(
            context, "isEnterFailed", getReasonInfo(enterExerciseFailedCode));
      }
    });
  }

  Timer? countdownTimer;

  void startTimer() {
    if (countdownTimer != null && countdownTimer!.isActive) return;
    countdownTimer =
        new Timer.periodic(new Duration(seconds: 3), (timer) async {
      if (!mounted) countdownTimer!.cancel();
      bool success = await HealyWatchSDKImplementation.instance
          .sendHeartPackage(HealyHeartPackageData(
              distanceInKm: 0.5,
              speedMinute: 5,
              speedSeconds: 30)); //心跳包。从app打开运动模式从app获取距离以及配速数据发送给手环
      print("$success");
    });
  }

  void cancelTimer() {
    if (countdownTimer != null && countdownTimer!.isActive)
      countdownTimer!.cancel();
  }

  String getReasonInfo(EnterExerciseFailed enterExerciseFailedCode) {
    String reasonInfo = "";
    switch (enterExerciseFailedCode) {
      case EnterExerciseFailed.none:
        break;
      case EnterExerciseFailed.alreadyEnter:
        reasonInfo = "Please exit the Work Out mode of the Healy Watch first.";
        break;
      case EnterExerciseFailed.ecgPPGMode:
        reasonInfo = "Currently in ECG and PPG state.";
        break;
      case EnterExerciseFailed.undefined:
        reasonInfo = "Open joint not defined.";
        break;
      case EnterExerciseFailed.sosMode:
        reasonInfo = "Currently in SOS emergency.";
        break;
      case EnterExerciseFailed.chargeMode:
        reasonInfo = "Currently charged.";
        break;
      case EnterExerciseFailed.resUpdateMode:
        reasonInfo = "Currently in UI upgrade mode.";
        break;
      case EnterExerciseFailed.modeNotChoose:
        reasonInfo = "No selection for current joint.";
        break;
    }
    return reasonInfo;
  }

  void showMsgDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getDialog(title, content);
      },
    );
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
          },
          child: Text("Confirm"),
        ),
      ],
    );
  }
}
