import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';

class NotifyPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NotifyPageState();
  }
}

class NotifyPageState extends State<NotifyPage> {
  bool enterCamera = false;
  HealyNotifierMode notifyType = HealyNotifierMode.dataStopTel;
  String title = "";
  String info = "";
  List<String> list = [
    "Incoming call",
    "SMS",
    "Wechat",
    "Facebook",
    "Instagram",
    "Skype",
    "Telegram",
    "Twitter",
    "VK",
    "WhatsApp",
    "Other Apps",
    "Email",
    "Line",
    "StopTel"
  ];

  TextEditingController _titleController = TextEditingController();
  TextEditingController _infoController = TextEditingController();
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
        title: Text("Notify"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: list.map((value) {
                return RadioListTile(
                  title: Text(value),
                  value: HealyNotifierMode.values[list.indexOf(value)],
                  groupValue: notifyType,
                  onChanged: (HealyNotifierMode? value) => sendNotify(value),
                );
              }).toList(),
            ),
          ),
          Column(
            children: <Widget>[
              TextField(
                decoration: InputDecoration(labelText: "Title"),
                textAlign: TextAlign.center,
                controller: _titleController,
              ),
              TextField(
                decoration: InputDecoration(labelText: "Info"),
                textAlign: TextAlign.center,
                controller: _infoController,
              ),
            ],
          ),
        ],
      ),
    );
  }

  sendNotify(HealyNotifierMode ?value) async {
    notifyType = value!;
    title = _titleController.text;
    info = _infoController.text;
    HealyNotifier healyNotifier = HealyNotifier(
      healyNotifierMode: notifyType,
      info: info,
      title: title,
    );
    bool success = await healyWatchSDK.setNotifyData(healyNotifier);
    print("$success");
    setState(() {});
  }
}
