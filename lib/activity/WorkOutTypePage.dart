



import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';




import '../button_view.dart';


class WorkOutTypePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return WorkOutTypePageState();
  }
}

class WorkOutTypePageState extends State<WorkOutTypePage> {
  List<String> listWorkType = [
    "Running",
    "Cycling",
    "Badminton",
    "Football",
    "Tennis",
    "Yoga",
    "Dancing",
    "Basketball",
    "Hiking",
    "Gym",
  ];


  @override
  void dispose() {
    super.dispose();

  }
  late HealyWatchSDKImplementation healyWatchSDK;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    healyWatchSDK= HealyWatchSDKImplementation.instance;

  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("WorkOutType"),
      ),
      body: Center(
          child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3.5,
                padding: EdgeInsets.all(4),
                children: getItemList(),
              ),
            ),
            Row(
              children: <Widget>[
                ButtonView("Get", action: () => getWorkOutType()),
                ButtonView("Set", action: () => setWorkOutType())
              ],
            )
          ],
        ),
      )),
    );
  }

  List<int> selected = [];
  List<Widget> getItemList() {
    return listWorkType.map((workOutType) {
      return getItem(workOutType);
    }).toList();
  }

  Widget getItem(String workOutType) {
    int index = listWorkType.indexOf(workOutType);
    return CheckboxListTile(
      title: Text(workOutType),
      value: selected.contains(index),
      onChanged: (bool) => changeChecked(bool!, index),
    );
  }

  changeChecked(bool isChecked, int index) {
    if (isChecked) {
      if (selected.length == 5) return;
      if (!selected.contains(index)) {
        selected.add(index);
      }
    } else {
      if (selected.contains(index)) {
        selected.remove(index);
      }
    }
    setState(() {});
  }

  getWorkOutType() async{
    HealyWorkoutType healyWorkoutType=await healyWatchSDK.getAllWorkoutTypes();
    this.selected = healyWorkoutType.selectedList;
    setState(() {});
  }

  setWorkOutType() async{
    bool isSetSuccess=await healyWatchSDK.setSelectedWorkoutTypes(HealyWorkoutType(selected));
    showMsgDialog(context, "SetWorkOutTypeResponse $isSetSuccess");
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
}
