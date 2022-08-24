import 'dart:io';

import 'package:flutter/material.dart';
import 'package:healywatch_reactive/activity/AncsPage.dart';
import 'package:healywatch_reactive/activity/AndroidNotifycationPage.dart';

import '../button_view.dart';
import 'AutomicHeartPage.dart';
import 'ClockListPage.dart';
import 'DeviceBasicPage.dart';
import 'DeviceInfoPage.dart';
import 'ExercisePage.dart';
import 'FirmwareUpdatePage.dart';
import 'GoalPage.dart';
import 'NotifyPage.dart';
import 'SedentaryReminderPage.dart';
import 'SleepModePage.dart';
import 'WatchFaceStylePage.dart';
import 'WeatherPage.dart';
import 'WorkOutReminderPage.dart';
import 'WorkOutTypePage.dart';

class DeviceSettingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return DeviceSettingPageState();
  }
}

class DeviceSettingPageState extends State<DeviceSettingPage> {
  bool enterCamera = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("DeviceSetting"),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              ButtonView(
                "WorkOutType",
                action: () => toWorkOutType(),
              ),
              ButtonView("WatchFaceStyle", action: () => toWatchFaceStyle())
            ],
          ),
          Row(
            children: <Widget>[
              ButtonView(
                "SedentaryReminderPage",
                action: () => toSedentaryReminder(),
              ),
              ButtonView("WorkOutReminder", action: () => toWorkOutReminder())
            ],
          ),
          Row(
            children: <Widget>[
              ButtonView(
                "AutomicHeartPage",
                action: () => toAutomicHeartPage(),
              ),
              ButtonView("Clock", action: () => toClockPage())
            ],
          ),
          Row(
            children: <Widget>[
              ButtonView(
                "DeviceBasicSetting",
                action: () => toDeviceBasicSetting(),
              ),
              ButtonView("DeviceInfo", action: () => toDeviceInfoPage())
            ],
          ),
          Row(
            children: <Widget>[
              ButtonView(
                "Goal",
                action: () => toSetGoal(),
              ),
              ButtonView(
                "Notify",
                action: () => toNotify(),
              )
            ],
          ),
          Row(
            children: <Widget>[
              ButtonView(
                "Exercise",
                action: () => toExercisePage(),
              ),
              ButtonView(
                "WeatherData",
                action: () => toWeatherData(),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              ButtonView(
                "SleepMode",
                action: () => toSleepModePage(),
              ),
              ButtonView(
                "FirmwareUpdate",
                action: () => toFirmwareUpdate(),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              ButtonView(
                "AncsState",
                action: () => toAncsStatePage(),
              ),
              Visibility(
                child: ButtonView(
                  "NotificationListener",
                  action: () => toNotificationPage(),
                ),
                visible: Platform.isAndroid,
              )
            ],
          ),
        ],
      ),
    );
  }

  toWorkOutType() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return WorkOutTypePage();
    }));
  }

  toWatchFaceStyle() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return WorkFaceStylePage();
    }));
  }

  toSedentaryReminder() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return SedentaryReminderPage();
    }));
  }

  toWorkOutReminder() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return WorkOutReminderPage();
    }));
  }

  toAutomicHeartPage() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return AutomicHeartPage();
    }));
  }

  toClockPage() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return ClockListPage();
    }));
  }

  toSetGoal() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return GoalPage();
    }));
  }

  toNotify() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return NotifyPage();
    }));
  }

  toDeviceInfoPage() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return DeviceInfoPage();
    }));
  }

  toDeviceBasicSetting() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return DeviceBasicPage();
    }));
  }

  toExercisePage() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return ExercisePage();
    }));
  }

  toWeatherData() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return WeatherPage();
    }));
  }

  toSleepModePage() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return SleepModePage();
    }));
  }

  toFirmwareUpdate() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return FirmwareUpdatePage();
    }));
  }

  toAncsStatePage() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return AncsPage();
    }));
  }

  toNotificationPage() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return AndroidNotifycationPage();
    }));
  }
}
