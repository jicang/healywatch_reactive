import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';

import 'package:healy_watch_sdk/model/models.dart';
import 'package:healy_watch_sdk/util/ble_sdk.dart';

import '../button_view.dart';

//ios需要设置，android通知在notifyPage
class AndroidNotifycationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AndroidNotifycationPageState();
  }
}

class AndroidNotifycationPageState extends State<AndroidNotifycationPage> {




  late HealyWatchSDKImplementation healyWatchSDK;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    healyWatchSDK = HealyWatchSDKImplementation.instance;
    initPlatformState();
    //selected = BleSdk.generateValue(list.length);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("AncsState"),
        ),
        body: Container(
          child: Row(
            children: [
            ButtonView("StartListener", action:() => startListening())

            ],
          ),
        ));
  }


 static const String PackageName_WeChat = "com.tencent.mm";
  static const String PackageName_Facebook = "com.facebook.katana";
  static const String PackageName_Facebook_orca = "com.facebook.orca";
  static const String PackageName_Twitter = "com.twitter.android";
  static const String PackageName_Skype = "com.skype.raider";
  static const String PackageName_WhatsApp = "com.whatsapp";
  static const String PackageName_Line = "jp.naver.line.android";
  static const String PackageName_Email = "com.google.android.gm";
  static const String PackageName_Ins = "com.instagram.android";
  static const String PackageName_Tel = "org.telegram.messenger";
  static const String PackageName_Vk = "com.vkontakte.android";



  ReceivePort port = ReceivePort();
  Future<void> initPlatformState() async {

    // this can fix restart<debug> can't handle error
    IsolateNameServer.removePortNameMapping("_listener_");
    IsolateNameServer.registerPortWithName(port.sendPort, "_listener_");
    port.listen((message) => onData(message));

    // don't use the default receivePort
    // NotificationsListener.receivePort.listen((evt) => onData(evt));

    var isR = await NotificationsListener.isRunning;
    print("""Service is ${isR}aleary running""");


  }

  void onData(NotificationEvent event) {
    var packageName=event.packageName;
    HealyNotifierMode healyNotifierMode=HealyNotifierMode.dataOther;
    switch(packageName){
      case PackageName_Vk:
        healyNotifierMode=HealyNotifierMode.dataVk;
        break;
      case PackageName_Tel:
        healyNotifierMode=HealyNotifierMode.dataTelegra;
        break;
      case PackageName_Ins:
        healyNotifierMode=HealyNotifierMode.dataINSTAGRAM;
        break;
      case PackageName_Line:
        healyNotifierMode=HealyNotifierMode.dataLine;
        break;
      case PackageName_WhatsApp:
        healyNotifierMode=HealyNotifierMode.dataWhatApp;
        break;
      case PackageName_WeChat:
        healyNotifierMode=HealyNotifierMode.dataWeChat;
        break;
      case PackageName_Skype:
        healyNotifierMode=HealyNotifierMode.dataSkype;
        break;
      case PackageName_Twitter:
        healyNotifierMode=HealyNotifierMode.dataTwitter;
        break;
      case PackageName_Facebook:
      case PackageName_Facebook_orca:
        healyNotifierMode=HealyNotifierMode.dataFacebook;
        break;
      case PackageName_Email:
        healyNotifierMode=HealyNotifierMode.dataEmail;
        break;
    }
    healyWatchSDK.setNotifyData(HealyNotifier(healyNotifierMode: healyNotifierMode, info: event.text.toString(), title: event.title.toString()));
    print(event.toString());
  }


  void startListening() async {
    print("start listening");
    var hasPermission = await NotificationsListener.hasPermission;
    if (!hasPermission!) {
      print("no permission, so open settings");
      NotificationsListener.openPermissionSettings();
      return;
    }
    var isR = await NotificationsListener.isRunning;
    if (!isR!) {
      await NotificationsListener.startService(
          title: "Listener Running",
          description: "Let's scrape the notifactions...");
    }


  }

  void stopListening() async {
    print("stop listening");



    await NotificationsListener.stopService();


  }

}
