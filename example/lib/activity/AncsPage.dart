import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';

import 'package:healy_watch_sdk/model/models.dart';
import 'package:healy_watch_sdk/util/ble_sdk.dart';

import '../button_view.dart';

//ios需要设置，android通知在notifyPage
class AncsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AncsPageState();
  }
}

class AncsPageState extends State<AncsPage> {
  bool enterCamera = false;
  HealyNotifierMode notifyType = HealyNotifierMode.dataStopTel;

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
    "QQ",
    "In",
  ];

  TextEditingController _titleController = TextEditingController();
  TextEditingController _infoController = TextEditingController();
  late HealyWatchSDKImplementation healyWatchSDK;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    healyWatchSDK = HealyWatchSDKImplementation.instance;
    //selected = BleSdk.generateValue(list.length);
  }

  bool enableAncs = false;

  List<HealyNotifierMode> selected = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("AncsState"),
        ),
        body: Container(
          child: Column(
            children: [
              SwitchListTile(
                title: Text("AncsEnable"),
                onChanged: (bool) => _enableAncs(bool),
                value: enableAncs,
              ),
              Divider(
                height: 1.0,
                color: Colors.amber,
              ),
              Expanded(
                  child: ListView(
                children: getWeekItem(),
                shrinkWrap: true,
              )),
              Container(
                height: 60,
                child: Row(
                  children: <Widget>[
                    ButtonView(
                      "Set",
                      action: () => setAncsState(),
                    ),
                    ButtonView(
                      "Get",
                      action: () => getAncsState(),
                    ),
                  ],
                ),
              )
            ],
          ),
        ));
  }

  _enableAncs(bool enable) async {
    this.enableAncs = enable;
    if (enable) {
      bool success = await HealyWatchSDKImplementation.instance.enableANCS();
      showMsgDialog(context, "enableANCS", "$success");
    } else {
      bool success = await HealyWatchSDKImplementation.instance.disableANCS();
      showMsgDialog(context, "disableANCS", "$success");
    }

    setState(() {});
  }

  List<Widget> getWeekItem() {
    return list.map((value) {
      int index = list.indexOf(value);
      HealyNotifierMode notifierMode = HealyNotifierMode.values[index];
      return CheckboxListTile(
        title: Text(value),
        value: selected.contains(notifierMode),
        onChanged: (bool) => changeChecked(bool!, notifierMode),
      );
    }).toList();
  }

  changeChecked(bool isChecked, HealyNotifierMode healyNotifierMode) {
    if (isChecked) {
      if (!selected.contains(healyNotifierMode)) {
        selected.add(healyNotifierMode);
      }
    } else {
      if (selected.contains(healyNotifierMode)) {
        selected.remove(healyNotifierMode);
      }
    }
    setState(() {});
  }

  setAncsState() async {
    bool success =
        await HealyWatchSDKImplementation.instance.setAncsState(selected);
    showMsgDialog(context, "setAncsState", "$success");
  }

  getAncsState() async {
    HealyDeviceBaseParameter healyDeviceBaseParameter =
        await HealyWatchSDKImplementation.instance.getDeviceBaseParameter();
    selected = healyDeviceBaseParameter.ancsList;
    enableAncs=healyDeviceBaseParameter.ancsState;
    setState(() {});
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

  void showMsgDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getDialog(title, content);
      },
    );
  }
}
