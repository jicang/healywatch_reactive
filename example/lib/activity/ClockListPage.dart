import 'dart:async';

import 'package:flutter/material.dart';
import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';





import '../button_view.dart';
import 'EditClockPage.dart';


class ClockListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ClockState();
  }
}

class ClockState extends State<ClockListPage> {


  @override
  void dispose() {
    super.dispose();

  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getClock();
  }



  List<HealyClock> list = [];

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: Text("ClockList"),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              ButtonView(
                "AddClock",
                action: () => toEditClock(-1),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              ButtonView(
                "GetClock",
                action: () => getClock(),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              ButtonView(
                "DeleteAllClock",
                action: () => showDeleteDialog(
                    context, "DeleteAllClock", "Whether DeleteAllClock"),
              ),
            ],
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.only(left: 8, right: 8),
              separatorBuilder: (context, index) {
                return new Container(height: 1.0, color: Colors.red);
              },
              itemBuilder: (context, index) {
                return getItemList(index);
              },
              itemCount: list.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget getItemList(int index) {
    return getItemChild(list[index]);
  }

  List<String> listWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  String getFormatString(int value) {
    String format = value.toString();
    if (format.length < 2) format = "0$format";
    return format;
  }

  Widget getItemChild(HealyClock clock) {
    String hour = getFormatString(clock.hour);
    String min = getFormatString(clock.minute);
//    String content = clock.content;
//    int clockType = clock.getType();
//    int id = clock.getType();
    bool enable = clock.enable;
    // int week = clock.week;
    // String week = map[DeviceKey.KAlarmWeekEnable];
    return GestureDetector(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 200,
                height: 40,
                color: Colors.transparent,
                child: Center(
                  child: Text(
                    "$hour:$min",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue, fontSize: 20),
                  ),
                ),
              ),
              Container(
                width: 200,
                height: 20,
                child: Center(
                  child: Text(
                    getWeekText(clock.weekEnableList),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Text(""),
          ),
          Switch(
            value: enable,
            onChanged: (bool) => changeClockEnable(bool),
          ),
        ],
      ),
      onTap: () => toEditClock(list.indexOf(clock)),
    );
  }

  String getWeekText(List<int> selected) {
    String weekString = "";
    for (int i = 0; i < selected.length; i++) {
      if (selected[i] == 1) {
        weekString += listWeek[i] + ",";
      }
    }
    return weekString;
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

  void showDeleteDialog(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getDialog(title, msg);
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
            deleteAllClock();
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



  syncFinish() {
    debugPrint("end s");
    //Navigator.of(context).pop(loadingDialog);
    setState(() {});
  }

  getClock() async {
    list.clear();
    setState(() {});
    Stream<List<HealyClock>> healySleepData = await HealyWatchSDKImplementation.instance.getAllClock();
    healySleepData.listen((event) {
      list.addAll(event);
    }, onDone: () => syncFinish());
  }

  changeClockEnable(bool param0) {
    setState(() {});
  }

  toEditClock(int position) async{
    await Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return EditClockPage(list, position);
    }));
    getClock();
  }

  void deleteAllClock() async {
    bool deleteSuccess = await HealyWatchSDKImplementation.instance.deleteAllClock();
    if (deleteSuccess) getClock();
  }
}
