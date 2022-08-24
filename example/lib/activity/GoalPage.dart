import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';

import '../button_view.dart';

class GoalPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return GoalPageState();
  }
}

class GoalPageState extends State<GoalPage> {
  TextEditingController _userAgeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Goal"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: "Goal"),
                    textAlign: TextAlign.center,
                    controller: _userAgeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                ButtonView(
                  "SetGoal",
                  action: () => setGoal(),
                ),
                ButtonView(
                  "GetGoal",
                  action: () => getGoal(),
                )
              ],
            ),
          ],
        ),
      ),
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
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Confim"),
        ),
      ],
    );
  }

  late AlertDialog alertDialog;

  void showMsgDialog(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getDialog(title, msg);
      },
    );
  }

  setGoal() async {
    String goal = _userAgeController.text;
    if (isEmpty(goal)) return;
    bool isSuccess = await HealyWatchSDKImplementation.instance
        .setStepTarget(int.parse(goal));
    showMsgDialog(context, "SetStepTargetResponse", "$isSuccess");
  }

  bool isEmpty(String value) {
    return value.length == 0;
  }

  getGoal() async {
    int goal = await HealyWatchSDKImplementation.instance.getStepTarget();
    _userAgeController.text = goal.toString();
    setState(() {});
  }
}
