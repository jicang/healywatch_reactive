import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';
import '../WeekDialog.dart';
import '../button_view.dart';

class WorkOutReminderPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return WorkOutReminderPageState();
  }
}

class WorkOutReminderPageState extends State<WorkOutReminderPage> {
  TextEditingController _workDaysController = TextEditingController();
  TextEditingController _intervalTimeController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
  }

  late HealyWatchSDKImplementation healyWatchSDK;
  @override
  void initState() {
    super.initState();
    healyWatchSDK = HealyWatchSDKImplementation.instance;
  }

  int selectedIndex = 0;
  bool enableSedentaryReminder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("WorkOutReminderPage"),
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
                        child: ElevatedButton(
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
                        child: ElevatedButton(
                          child: Text(week),
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
                      SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(labelText: "WorkOutDays"),
                          textAlign: TextAlign.center,
                          controller: _workDaysController,
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
                      ButtonView("Get", action: () => getWorkOutReminder()),
                      ButtonView("Set", action: () => setWorkOutReminder())
                    ],
                  ),
                ],
              ))),
    );
  }

  late bool isSet;

  getWorkOutReminder() async {
    HealyWorkoutReminderSettings workOutReminder =
        await healyWatchSDK.getWorkoutReminderSettings();
    int startHour = workOutReminder.hour;
    int startMin = workOutReminder.minute;
    int timeInterval = workOutReminder.duration;
    enableSedentaryReminder = workOutReminder.isEnabled;
    selected = workOutReminder.daysInWeek;
    int days = workOutReminder.days;
    startTime = getFormatString(startHour) + ":" + getFormatString(startMin);
    _intervalTimeController.text = timeInterval.toString();
    _workDaysController.text = days.toString();
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
        child: Text("Set"),
      ),
      content: Text(dataType),
      actions: <Widget>[
        TextButton(
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
  String week = "";

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
    weekDialog = WeekDialog(selected);
    return new AlertDialog(
      title: Container(
        width: MediaQuery.of(context).size.width,
        child: Text("WeekEnable"),
      ),
      content: weekDialog,
      actions: <Widget>[
        TextButton(
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

  int weekSet = 0;

  void changeWeekText() {
    week = getWeekText();
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

  setWorkOutReminder() async {
    List<String> listStart = startTime.split(":");
    String intervalTime = _intervalTimeController.text;
    String leastStep = _workDaysController.text;
    if (isEmpty(intervalTime) || isEmpty(leastStep)) return;
    HealyWorkoutReminderSettings reminderSettings =
        HealyWorkoutReminderSettings(
      hour: int.parse(listStart[0]),
      minute: int.parse(listStart[1]),
      daysInWeek: selected,
      duration: int.parse(intervalTime),
      isEnabled: enableSedentaryReminder,
      days: int.parse(leastStep),
    );

    bool isSetSuccess =
        await healyWatchSDK.setWorkoutReminder(reminderSettings);

    showMsgDialog(context, "SetWorkOutReminder  $isSetSuccess");
  }

  bool isEmpty(String value) {
    return value.length == 0;
  }

  changeEnable(bool param0) {
    enableSedentaryReminder = param0;
    setState(() {});
  }
}
