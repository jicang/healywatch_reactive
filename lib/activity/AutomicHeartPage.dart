import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';

import '../WeekDialog.dart';
import '../button_view.dart';

class AutomicHeartPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AutomicHeartPageState();
  }
}

class AutomicHeartPageState extends State<AutomicHeartPage> {
  TextEditingController _intervalTimeController = TextEditingController();

  int selectedIndex = 0;
  bool enableSedentaryReminder = false;

  HeartRateMeasurementMode workMode = HeartRateMeasurementMode.off;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AutomicHeartPage"),
      ),
      body: Center(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text("Off"),
                      Radio(
                        value: HeartRateMeasurementMode.off,
                        groupValue: workMode,
                        onChanged: (HeartRateMeasurementMode? value) =>
                            changeWorkMode(value),
                      ),
                      Text("On"),
                      Radio(
                        value: HeartRateMeasurementMode.on,
                        groupValue: workMode,
                        onChanged: (HeartRateMeasurementMode ?value) =>
                            changeWorkMode(value),
                      ),
                      Text("Interval"),
                      Radio(
                        value: HeartRateMeasurementMode.interval,
                        groupValue: workMode,
                        onChanged: (HeartRateMeasurementMode? value) =>
                            changeWorkMode(value),
                      ),
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
                      Expanded(
                        child: Text(
                          "Week",
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: RaisedButton(
                          child: Text(weekString),
                          onPressed: () => showWeekDialog(),
                        ),
                      )
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          decoration:
                              InputDecoration(labelText: "IntervalTime"),
                          textAlign: TextAlign.center,
                          controller: _intervalTimeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      ButtonView("Get", action: () => getSedentaryReminder()),
                      ButtonView("Set", action: () => setSedentaryReminder())
                    ],
                  ),
                ],
              ))),
    );
  }

  bool ?isSet;

  getSedentaryReminder() async {
    HealyHeartRateMeasurementSettings automicHeart =
        await HealyWatchSDKImplementation.instance
            .getHeartRateMessurementSettings();
    int startHour = automicHeart.startHour;
    int startMin = automicHeart.startMinute;
    int endHour = automicHeart.endHour;
    int endMin = automicHeart.endMinute;
    int timeInterval = automicHeart.intervalTime;
    workMode = automicHeart.measurementMode;
    selected = automicHeart.daysInWeek;
    startTime = getFormatString(startHour) + ":" + getFormatString(startMin);
    endTime = getFormatString(endHour) + ":" + getFormatString(endMin);
    _intervalTimeController.text = timeInterval.toString();

    changeWeekText();
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

  AlertDialog ?alertDialog;

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
  String weekString = "";

  showTimePickerDialog(int timeMode) async {
    List<String> list =
        timeMode == 0 ? startTime.split(":") : endTime.split(":");
    TimeOfDay? picker = await showTimePicker(
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

  showWeekDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getChildList();
      },
    );
  }

  late WeekDialog weekDialog;
  List<int> selected = [];
  List<String> listWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  AlertDialog getChildList() {
    weekDialog = WeekDialog(selected);
    return new AlertDialog(
      title: Container(
        width: MediaQuery.of(context).size.width,
        child: Text("WeekEnable"),
      ),
      content: weekDialog,
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
            changeWeekText();
            setState(() {});
          },
          child: Text("Confirm"),
        )
      ],
    );
  }

  String getWeekText() {
    String weekString = "";
    for (int i = 0; i < selected.length; i++) {
      if (selected[i] == 1) {
        weekString += listWeek[i] + ",";
      }
    }
    return weekString;
  }

  void changeWeekText() {
    weekString = getWeekText();
  }

  setSedentaryReminder() async {
    List<String> listStart = startTime.split(":");
    List<String> listEnd = endTime.split(":");
    String intervalTime = _intervalTimeController.text;
    if (isEmpty(intervalTime)) return;

    HealyHeartRateMeasurementSettings healyHeartRateMesaurementSettings =
        HealyHeartRateMeasurementSettings(
      measurementMode: workMode,
      startHour: int.parse(listStart[0]),
      startMinute: int.parse(listStart[1]),
      endHour: int.parse(listEnd[0]),
      endMinute: int.parse(listEnd[1]),
      intervalTime: int.parse(intervalTime),
      daysInWeek: selected,
    );

    bool isSetSuccess = await HealyWatchSDKImplementation.instance
        .setHeartRateMeasurementSettings(healyHeartRateMesaurementSettings);

    showMsgDialog(context, "SetAutoMeasureHeartRateResponse $isSetSuccess");
  }

  bool isEmpty(String value) {
    return null == value || value.length == 0;
  }

  changeEnable(bool param0) {}

  changeWorkMode(HeartRateMeasurementMode? mode) {
    workMode = mode!;
    setState(() {});
  }
}
