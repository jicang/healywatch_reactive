import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';

import '../WeekDialog.dart';
import '../button_view.dart';

class SleepModePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SleepModePageState();
  }
}

class SleepModePageState extends State<SleepModePage> {
  @override
  void dispose() {
    super.dispose();
  }

  int selectedIndex = 0;
  bool enableSedentaryReminder = false;
  late HealyWatchSDKImplementation healyWatchSDK;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    healyWatchSDK = HealyWatchSDKImplementation.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SleepModePage"),
      ),
      body: Center(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Switch(
                        value: enableSedentaryReminder,
                        onChanged: (bool) => changeEnable(bool),
                      )
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Text(
                          "Start:",
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: RaisedButton(
                          child: Text(startTime),
                          onPressed: () => showTimePickerDialog(0),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Text(
                          "End:",
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: RaisedButton(
                          child: Text(endTime),
                          onPressed: () => showTimePickerDialog(1),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      ButtonView("Get", action: () => getSleepModeData()),
                      ButtonView("Set", action: () => setSleepModeData())
                    ],
                  ),
                ],
              ))),
    );
  }

  late bool isSet;

  getSleepModeData() async {
    HealySleepModeData healySleepModeData =
        await healyWatchSDK.getHealySleepMode();
    int startHour = healySleepModeData.startHour;
    int startMin = healySleepModeData.startMin;
    int endHour = healySleepModeData.endHour;
    int endMin = healySleepModeData.endMin;
    enableSedentaryReminder = healySleepModeData.isEnabled;
    startTime = getFormatString(startHour) + ":" + getFormatString(startMin);
    endTime = getFormatString(endHour) + ":" + getFormatString(endMin);
    setState(() {});
  }

  String getFormatString(int value) {
    String format = value.toString();
    if (format.length < 2) format = "0$format";
    return format;
  }

  Widget getDialog(String dataType) {
    return new AlertDialog(
      title: Container(
        width: MediaQuery.of(context).size.width,
        child: Text(dataType),
      ),
      content: Text("Set SuccessFul"),
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

  late AlertDialog alertDialog;

  void showMsgDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getDialog(title);
      },
    );
  }

  String startTime = "08:00";
  String endTime = "12:00";
  String week = "";

  showTimePickerDialog(int timeMode) async {
    List<String> list =
        timeMode == 0 ? startTime.split(":") : endTime.split(":");
    var picker = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay(hour: int.parse(list[0]), minute: int.parse(list[1])),
        builder: (context, child) {
          return MediaQuery(
            child: child!,
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          );
        });
    String selectedTime =
        getFormatString(picker!.hour) + ":" + getFormatString(picker.minute);
    if (timeMode == 0) {
      startTime = selectedTime;
    } else {
      endTime = selectedTime;
    }
    setState(() {});
  }

  setSleepModeData() async {
    List<String> listStart = startTime.split(":");
    List<String> listEnd = endTime.split(":");
    HealySleepModeData healySleepModeData = HealySleepModeData(
      startHour: int.parse(listStart[0]),
      startMin: int.parse(listStart[1]),
      endHour: int.parse(listEnd[0]),
      endMin: int.parse(listEnd[1]),
      isEnabled: enableSedentaryReminder,
    );
    bool setSuccess = await healyWatchSDK.setHealySleepMode(healySleepModeData);
    showMsgDialog(context, "SedentaryReminder ${setSuccess}");
  }

  changeEnable(bool param0) {
    enableSedentaryReminder=param0;
    setState(() {

    });
  }
}
