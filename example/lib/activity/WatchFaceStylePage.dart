
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';




import '../button_view.dart';


class WorkFaceStylePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return WorkFaceStylePageState();
  }
}

class WorkFaceStylePageState extends State<WorkFaceStylePage> {

  @override
  void dispose() {
    super.dispose();

  }

  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("WorkFaceStyle"),
      ),
      body: Center(
          child: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Image.asset(
                          "images/watch_style1.png",
                          width: 200,
                          height: 200,
                        ),
                        Radio(
                          groupValue: selectedIndex,
                          value: 0,
                          onChanged: (int ?value) => setSelectedValue(value),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Image.asset(
                          "images/watch_style2.png",
                          width: 200,
                          height: 200,
                        ),
                        Radio(
                          groupValue: selectedIndex,
                          value: 1,
                          onChanged: (int? value) => setSelectedValue(value),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Image.asset(
                          "images/watch_style3.png",
                          width: 200,
                          height: 200,
                        ),
                        Radio(
                          groupValue: selectedIndex,
                          value: 3,
                          onChanged: (int? value) => setSelectedValue(value),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Image.asset(
                          "images/watch_style4.png",
                          width: 200,
                          height: 200,
                        ),
                        Radio(
                          groupValue: selectedIndex,
                          value: 4,
                          onChanged: (int ?value) => setSelectedValue(value),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  ButtonView("Get", action: () => getWatchStyle()),
                  ButtonView("Set", action: () => setWatchStyle())
                ],
              )
            ],
          ),
        ),
      )),
    );
  }

  bool isSet = false;
  getWatchStyle() async{
    HealyWatchFaceStyle healyWatchFaceStyle=await HealyWatchSDKImplementation.instance.getSelectedWatchFaceStyles();
    selectedIndex = healyWatchFaceStyle.imageId;
    setState(() {});
  }

  setWatchStyle() async{
    isSet = true;
    bool isSuccess=await HealyWatchSDKImplementation.instance.setWatchFaceStyle(HealyWatchFaceStyle(selectedIndex));
    debugPrint("$isSuccess");

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
          child: Text("Confim"),
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

  setSelectedValue(int ?value) {
    this.selectedIndex = value!;
    setState(() {});
  }
}
