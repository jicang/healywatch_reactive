import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';

import '../WeekDialog.dart';
import '../button_view.dart';

class EditClockPage extends StatefulWidget {
  final List<HealyClock> list;
  final int clockId;

  EditClockPage(this.list, this.clockId);

  @override
  State<StatefulWidget> createState() {
    return EditClockPageState(list, clockId);
  }
}

class EditClockPageState extends State<EditClockPage> {
  List<HealyClock> list = [];
  late HealyClock clock;
  int clockId = -1;
  String startTime = "08:00";
  String weekString = "";
  HealyClockMode clockType = HealyClockMode.ordinary;
  int selectedIndex = 0;
  bool enableSedentaryReminder = false;
  TextEditingController _intervalTimeController = TextEditingController();

  EditClockPageState(this.list, this.clockId);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (clockId == -1) {
      clock = new HealyClock();
      clock.id = list.length + 1;
      clock.hour = 8;
      clock.minute = 0;
      clock.enable = true;
      clock.healyClockMode = HealyClockMode.ordinary;
      clock.weekEnableList = List.generate(7, (index) => 1);
      if (clockId == -1) list.add(clock);
    } else {
      clock = list[clockId];
    }

    String hour = getFormatString(clock.hour);
    String min = getFormatString(clock.minute);
    enableSedentaryReminder = clock.enable;
    clockType = clock.healyClockMode;

    selected = clock.weekEnableList;
    weekString = getWeekText();
    startTime = "$hour:$min";
    _intervalTimeController.text = clock.content;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("EditClock"),
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
                        child: TextField(
                          decoration: InputDecoration(labelText: "ClockInfo"),
                          textAlign: TextAlign.center,
                          controller: _intervalTimeController,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      RadioListTile(
                        title: Text("Ordinary"),
                        value: HealyClockMode.ordinary,
                        groupValue: clockType,
                        onChanged: (HealyClockMode? value) =>
                            changeWorkMode(value),
                      ),
                      RadioListTile(
                        title: Text("Pill Reminder"),
                        value: HealyClockMode.pillReminder,
                        groupValue: clockType,
                        onChanged: (HealyClockMode? value) =>
                            changeWorkMode(value),
                      ),
                      RadioListTile(
                        title: Text("Healy Day"),
                        value: HealyClockMode.healyDay,
                        groupValue: clockType,
                        onChanged: (HealyClockMode? value) =>
                            changeWorkMode(value),
                      ),
                      RadioListTile(
                        title: Text("Healy Night"),
                        value: HealyClockMode.healyNight,
                        groupValue: clockType,
                        onChanged: (HealyClockMode? value) =>
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
                          onPressed: () => showTimePickerDialog(),
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
                      ButtonView("Set", action: () => setSedentaryReminder()),
                    ],
                  ),
                  Offstage(
                    offstage: clockId == -1,
                    child: Row(
                      children: <Widget>[
                        ButtonView(
                          "Delete",
                          action: () => deleteClock(),
                        )
                      ],
                    ),
                  )
                ],
              ))),
      resizeToAvoidBottomInset: false,
    );
  }

  late bool isSet;

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

  showTimePickerDialog() async {
    List<String> list = startTime.split(":");
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
    startTime = selectedTime;
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
    if (weekDialog == null) weekDialog = WeekDialog(selected);
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

  void changeWeekText() {
    weekString = getWeekText();
  }

  setSedentaryReminder() {
    List<String> listStart = startTime.split(":");
    String content = _intervalTimeController.text;
    clock.hour = int.parse(listStart[0]);
    clock.minute = int.parse(listStart[1]);
    clock.healyClockMode = clockType;
    clock.content = isEmpty(content) ? "" : content;
    clock.enable = enableSedentaryReminder;
    clock.weekEnableList = selected;
    //clock.week = weekSet;
    setClock();
  }

  void setClock() async {
    bool isSuccess = await HealyWatchSDKImplementation.instance.editClock(list);
    showMsgDialog(context, "SetAlarmClock");
    debugPrint("$isSuccess");
  }

  bool isEmpty(String value) {
    return null == value || value.length == 0;
  }

  changeEnable(bool enable) {
    enableSedentaryReminder = enable;
    setState(() {});
  }

  changeWorkMode(HealyClockMode? value) {
    clockType = value!;
    setState(() {});
  }

  deleteClock() {
    list.remove(clock);
    setClock();
  }
}
