import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';

import '../button_view.dart';

class DeviceInfoPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return DeviceInfoPageState();
  }
}

class DeviceInfoPageState extends State<DeviceInfoPage> {
  bool enterCamera = false;
  bool enterMusic = false;
  bool realTimeStep = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController _userAgeController = TextEditingController();

  String info = "";

  @override
  void initState() {
    super.initState();
    Stream<HealyFunction> stream =
        HealyWatchSDKImplementation.instance.listenFunctionMode();
    stream.listen((function) {
      switch (function) {
        case HealyFunction.camera:
          print("camera");
          break;
        case HealyFunction.rejectTel:
          print("rejectTel");
          break;
        case HealyFunction.tel:
          print("tel");
          break;
        case HealyFunction.findPhone:
          print("findPhone");
          break;
        case HealyFunction.musicControlPlay:
          print("musicControlPlay");
          break;
        case HealyFunction.musicControlNext:
          print("musicControlNext");
          break;
        case HealyFunction.musicControlPre:
          print("musicControlPre");
          break;
        case HealyFunction.musicControlPause:
          print("musicControlPause");
          break;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
  BuildContext? mContext;
  @override
  Widget build(BuildContext context) {
    mContext=context;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("DeviceInfo"),
      ),
      body: SingleChildScrollView(child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              ButtonView(
                "MCUReset",
                action: () => setMCUReset(),
              ),
              ButtonView("FactoryMode", action: () => enterFactoryMode())
            ],
          ),
          Row(
            children: <Widget>[
              ButtonView(
                "Battery",
                action: () => getDeviceBattery(),
              ),
              ButtonView("MacAddress", action: () => getMacAddress())
            ],
          ),
          Row(
            children: <Widget>[
              ButtonView(
                "DeviceVersion",
                action: () => getDeviceVersion(),
              ),
              ButtonView("GetSerialNumber", action: () => toGetSerialNumber()),
            ],
          ),
          Column(
            children: <Widget>[
              SwitchListTile(
                title: Text("Camera control"),
                value: enterCamera,
                onChanged: (bool) => enterCameraMode(bool),
              )
            ],
          ),
          Column(
            children: <Widget>[
              SwitchListTile(
                title: Text("Music control"),
                value: enterMusic,
                onChanged: (bool) => enterMusicMode(bool),
              )
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child:              TextField(
                  decoration: InputDecoration(labelText: "DeviceId"),
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  controller: _userAgeController,
                ) ,
              )
              ,
              ButtonView(
                "Set DeviceId",
                action: () => setDeviceID(context),
              )
            ],
          ),
          Column(
            children: <Widget>[
              SwitchListTile(
                title: Text("RealTimeStep"),
                value: realTimeStep,
                onChanged: (bool) => enableRealTime(bool),
              )
            ],
          ),
          Text(info)
        ],
      ),)
    );
  }

  getDeviceBattery() async {
    int level = await HealyWatchSDKImplementation.instance.getBatteryLevel();
    showMsgDialog(this.context, "battery", "$level %");
  }

  getDeviceVersion() async {
    String deviceVersion =
        await HealyWatchSDKImplementation.instance.getFirmwareVersion();
    showMsgDialog(context, "FirmwareVersion", "$deviceVersion");
  }

  getMacAddress() async {
    String address =
        await HealyWatchSDKImplementation.instance.getDeviceAddress();
    showMsgDialog(context, "DeviceAddress", "$address");
  }

  setMCUReset() async {
    bool isSuccess = await HealyWatchSDKImplementation.instance.setMCUReset();
    showMsgDialog(context, "setMCUReset", "$isSuccess");
  }

  enterFactoryMode() {
    showDeleteDialog(context, "Caution!",
        "Factory Reset will clear all the data in the device, please confirm that you want to reset");
  }

  toGetSerialNumber() async {
    String serialNumber =
        await HealyWatchSDKImplementation.instance.getSerialNumber();
    showMsgDialog(context, "serialNumber", "$serialNumber");
  }

  Widget getDialog(String dataType, String msg) {
    return new AlertDialog(
      title: Container(
        width: MediaQuery.of(mContext!).size.width,
        child: Text(dataType),
      ),
      content: Text(msg),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.of(mContext!).pop();
          },
          child: Text("Confirm"),
        ),
      ],
    );
  }

  late AlertDialog alertDialog;

  void showMsgDialog(BuildContext context, String title, String content) {
    showDialog(
      context: mContext!,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getDialog(title, content);
      },
    );
  }

  void showDeleteDialog(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getDeleteDialog(title, msg);
      },
    );
  }

  Widget getDeleteDialog(String dataType, String msg) {
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
            HealyWatchSDKImplementation.instance.setFactoryMode();
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

  enterCameraMode(bool value) async {
    enterCamera = value;
    setState(() {});
    if (enterCamera) {
      bool isSuccess =
          await HealyWatchSDKImplementation.instance.enableCamera();
      showMsgDialog(context, "enableCamera", "$isSuccess");
    } else {
      bool isSuccess =
          await HealyWatchSDKImplementation.instance.backWatchHomePage();
      showMsgDialog(context, "backWatchHomePage", "$isSuccess");
    }
  }

  enterMusicMode(bool value) async {
    enterMusic = value;
    setState(() {});
    if (enterMusic) {
      bool isSuccess = await HealyWatchSDKImplementation.instance.enableMusic();
      showMsgDialog(context, "enableMusic", "$isSuccess");
    } else {
      bool isSuccess =
          await HealyWatchSDKImplementation.instance.backWatchHomePage();
      showMsgDialog(context, "backWatchHomePage", "$isSuccess");
    }
  }

  enableRealTime(bool value) async {
    realTimeStep = value;
    setState(() {});

    if (realTimeStep) {
      if(!mounted)return;
      Stream<HealyRealTimeStep> realStream =
          await HealyWatchSDKImplementation.instance.enableRealTimeStep();
      realStream.listen((event) {
        showRealTimeStepInfo(event);
      });
    } else {
      bool isSuccess =
          await HealyWatchSDKImplementation.instance.disableRealTimeStep();
      showMsgDialog(context, "disableRealTimeStep", "$isSuccess");
    }
  }

  startRealTimeStep() async {}
  setDeviceID(BuildContext context) async {
    String deviceID = _userAgeController.text;
    if (deviceID == null || deviceID.length == 0) {
      SnackBar snackBar = new SnackBar(content: new Text('DeviceId is empty'));

      _scaffoldKey.currentState!.showSnackBar(snackBar);
      return;
    }
    bool isSuccess =
        await HealyWatchSDKImplementation.instance.setDeviceId(deviceID);
    showMsgDialog(context, "setDeviceID", "$isSuccess");
  }

  void showRealTimeStepInfo(HealyRealTimeStep baseResponse) {
    var dateTime = baseResponse.dateTime;
    var step = baseResponse.steps;
    var cal = baseResponse.burnedCalories;
    var distance = baseResponse.distanceInKm;
    var heartRate = baseResponse.heartRate;
    var workoutMin = baseResponse.workoutMinutes;
    var activeMin = baseResponse.activeMinutes;
    info = "Step: $step\n"
        "Datetime: $dateTime \n"
        "Calories: $cal KCAL\n"
        "Distance: $distance KM\n"
        "HeartRate: $heartRate bpm\n"
        "SportTime: $workoutMin second\n"
        "ExerciseTime: $activeMin min\n";
    if(mounted)
    setState(() {});
  }
}
