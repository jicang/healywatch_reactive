import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';

import '../button_view.dart';

class DeviceBasicPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return DeviceBasicPageState();
  }
}

class DeviceBasicPageState extends State<DeviceBasicPage> {
  DistanceUnit? distanceUnit;
  HourMode? timeMode;
  WearingWrist? wearingWrist;
  bool enableWristOn = false;
  bool enableSos = false;
  bool enableConnectVibration = false;
  double wristOnSensitivity = 1;
  double screenLight = 1;
  double screenOnTime = 1;
  double vibrationLevel = 1;

  TextEditingController _userAgeController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("DeviceBaseInfo"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(
                    "Distance",
                    textAlign: TextAlign.center,
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: RadioListTile(
                    title: Text("Metric"),
                    value: DistanceUnit.metric,
                    groupValue: distanceUnit,
                    onChanged: (DistanceUnit? value) =>
                        changeDistanceUnit(value),
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: RadioListTile(
                    title: Text("Imperial"),
                    value: DistanceUnit.imperial,
                    groupValue: distanceUnit,
                    onChanged: (DistanceUnit? value) =>
                        changeDistanceUnit(value),
                  ),
                ),
              ],
            ),
            Divider(
              height: 1.0,
              color: Colors.amber,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(
                    "Hour",
                    textAlign: TextAlign.center,
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: RadioListTile(
                    title: Text("12h"),
                    value: HourMode.hourMode_12,
                    groupValue: timeMode,
                    onChanged: (HourMode? value) => changeTimeMode(value),
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: RadioListTile(
                    title: Text("24h"),
                    value: HourMode.hourMode_24,
                    groupValue: timeMode,
                    onChanged: (HourMode? value) => changeTimeMode(value),
                  ),
                ),
              ],
            ),
            Divider(
              height: 1.0,
              color: Colors.amber,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(
                    "Wearing Wrist",
                    textAlign: TextAlign.center,
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: RadioListTile(
                    title: Text("Left"),
                    value: WearingWrist.left,
                    groupValue: wearingWrist,
                    onChanged: (WearingWrist? value) => changeHand(value),
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: RadioListTile(
                    title: Text("Right"),
                    value: WearingWrist.right,
                    groupValue: wearingWrist,
                    onChanged: (WearingWrist? value) => changeHand(value),
                  ),
                ),
              ],
            ),
            Divider(
              height: 1.0,
              color: Colors.amber,
            ),
            SwitchListTile(
              title: Text("Wrist-on Function"),
              onChanged: (bool) => _enableWristOn(bool),
              value: enableWristOn,
            ),
            Divider(
              height: 1.0,
              color: Colors.amber,
            ),
            SwitchListTile(
              title: Text("Sos Function"),
              onChanged: (bool) => _enableSos(bool),
              value: enableSos,
            ),
            Divider(
              height: 1.0,
              color: Colors.amber,
            ),
            SwitchListTile(
              title: Text("Connect Vibration"),
              onChanged: (bool) => _enableConnectVibration(bool),
              value: enableConnectVibration,
            ),
            Divider(
              height: 1.0,
              color: Colors.amber,
            ),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text("Wrist-On Sensitivity"),
            ),
            Slider(
              label: "$wristOnSensitivity",
              value: wristOnSensitivity,
              onChanged: (value) => changeWristOnSensitivity(value),
              onChangeEnd: (value) => setWristOnSensitivity(value),
              min: 1.0,
              divisions: 2,
              max: 3.0,
            ),
            Divider(
              height: 1.0,
              color: Colors.amber,
            ),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text("BrightnessLevel"),
            ),
            Slider(
              label: "$screenLight",
              value: screenLight,
              onChanged: (value) => changeScreenLight(value),
              onChangeEnd: (value) => setWScreenLight(value),
              min: 1.0,
              divisions: 14,
              max: 15.0,
            ),
            Divider(
              height: 1.0,
              color: Colors.amber,
            ),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text("Screen-On Time"),
            ),
            Slider(
              label: "$screenOnTime",
              value: screenOnTime,
              onChanged: (value) => changeScreenOnTime(value),
              onChangeEnd: (value) => setScreenOnTime(value),
              min: 1.0,
              divisions: 7,
              max: 8,
            ),
            Divider(
              height: 1.0,
              color: Colors.amber,
            ),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text("Vibration Level"),
            ),
            Slider(
              label: "$vibrationLevel",
              value: vibrationLevel,
              onChanged: (value) => changeData(value),
              onChangeEnd: (value) => setVibrationLevel(value),
              min: 1.0,
              divisions: 4,
              max: 5,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration:
                        InputDecoration(labelText: "Base HeartRate(>40)"),
                    textAlign: TextAlign.center,
                    controller: _userAgeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                ),
                ButtonView(
                  "Set BaseHeartRate",
                  action: () => setBaseHr(),
                )
              ],
            ),
            Row(
              children: <Widget>[
                ButtonView(
                  "Set DeviceInfo",
                  action: () => setDeviceInfo(),
                ),
                ButtonView(
                  "Get DeviceInfo",
                  action: () => getDeviceInfo(),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  getDeviceInfo() async {
    HealyDeviceBaseParameter deviceBaseParameter =
        await HealyWatchSDKImplementation.instance.getDeviceBaseParameter();
    distanceUnit = deviceBaseParameter.distanceUnit;
    timeMode = deviceBaseParameter.hourMode;
    wearingWrist = deviceBaseParameter.wearingWrist;
    enableWristOn = deviceBaseParameter.wristOnEnable!;
    wristOnSensitivity = deviceBaseParameter.wristOnSensitivity!.toDouble();
    if (wristOnSensitivity < 1 || wristOnSensitivity > 3)
      wristOnSensitivity =
          HealyDeviceBaseParameter.defaultWristOnSensitivity.toDouble();
    vibrationLevel = deviceBaseParameter.vibrationLevel!.toDouble();
    if (vibrationLevel < 1 || vibrationLevel > 5)
      vibrationLevel =
          HealyDeviceBaseParameter.defaultVibrationLevel.toDouble();
    screenOnTime = deviceBaseParameter.screenOnTime!.toDouble();
    if (screenOnTime < 1 || screenOnTime > 8)
      screenOnTime = HealyDeviceBaseParameter.defaultScreenOnTime.toDouble();
    screenLight = deviceBaseParameter.brightnessLevel!.toDouble();
    if (screenLight < 1 || screenLight > 15)
      screenLight = HealyDeviceBaseParameter.defaultBrightnessLevel.toDouble();

    enableSos = deviceBaseParameter.sosEnable!;
    _userAgeController.text = deviceBaseParameter.baseHeart.toString();
    enableConnectVibration = deviceBaseParameter.connectVibration!;
    setState(() {});
  }

  setDeviceInfo() async {
    HealyDeviceBaseParameter deviceBaseParameter =
        new HealyDeviceBaseParameter();
    String hr = _userAgeController.text;
    if (hr != null && hr.length != 0)
      deviceBaseParameter.baseHeart = int.parse(hr);
    deviceBaseParameter.screenOnTime = screenOnTime.toInt();
    deviceBaseParameter.brightnessLevel = screenLight.toInt();
    deviceBaseParameter.wristOnSensitivity = wristOnSensitivity.toInt();
    deviceBaseParameter.vibrationLevel = vibrationLevel.toInt();
    deviceBaseParameter.sosEnable = enableSos;
    deviceBaseParameter.connectVibration = enableConnectVibration;
    deviceBaseParameter.wristOnEnable = enableWristOn;
    deviceBaseParameter.distanceUnit = distanceUnit;
    deviceBaseParameter.hourMode = timeMode;
    deviceBaseParameter.wearingWrist = wearingWrist;
    bool isSuccess = await HealyWatchSDKImplementation.instance
        .setDeviceBaseParameter(deviceBaseParameter);
    print("$isSuccess");
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

  AlertDialog? alertDialog;

  void showMsgDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getDialog(title, content);
      },
    );
  }

  changeDistanceUnit(DistanceUnit? value) {
    distanceUnit = value!;
    HealyWatchSDKImplementation.instance.setDistanceUnit(distanceUnit!);
    setState(() {});
  }

  changeTimeMode(HourMode? value) {
    timeMode = value!;
    HealyWatchSDKImplementation.instance.setTimeModeUnit(timeMode!);
    setState(() {});
  }

  changeHand(WearingWrist? value) {
    wearingWrist = value!;
    HealyWatchSDKImplementation.instance.setWearingWrist(wearingWrist!);
    setState(() {});
  }

  _enableWristOn(bool enable) {
    this.enableWristOn = enable;
    HealyWatchSDKImplementation.instance.enableWristOn(enableWristOn);
    setState(() {});
  }

  _enableSos(bool enable) {
    this.enableSos = enable;
    HealyWatchSDKImplementation.instance.setSosEnable(enableSos);
    setState(() {});
  }

  _enableConnectVibration(bool enable) {
    this.enableConnectVibration = enable;
    HealyWatchSDKImplementation.instance
        .setConnectVibration(enableConnectVibration);
    setState(() {});
  }

  changeWristOnSensitivity(double value) {
    this.wristOnSensitivity = value;
    setState(() {});
  }

  setWristOnSensitivity(double value) {
    HealyWatchSDKImplementation.instance.setWristOnSensitivity(value.toInt());
  }

  changeScreenLight(double value) {
    this.screenLight = value;
    setState(() {});
  }

  setWScreenLight(double value) {
    HealyWatchSDKImplementation.instance.setBrightnessLevel(value.toInt());
  }

  changeScreenOnTime(double value) {
    this.screenOnTime = value;
    setState(() {});
  }

  changeData(double value) {
    vibrationLevel = value;
    setState(() {});
  }

  setScreenOnTime(double value) {
    HealyWatchSDKImplementation.instance.setScreenOnTime(value.toInt());
  }

  setVibrationLevel(double value) {
    HealyWatchSDKImplementation.instance.setVibrationLevel(value.toInt());
  }

  setBaseHr() {
    String hr = _userAgeController.text;
    if ( hr.length == 0) return;
    HealyWatchSDKImplementation.instance.setBaseHeartRate(int.parse(hr));
  }
}
