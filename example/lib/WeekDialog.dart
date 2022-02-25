import 'package:flutter/material.dart';

class WeekDialog extends StatefulWidget {
  final List<int> selected;
  WeekDialog(this.selected);
  @override
  State<StatefulWidget> createState() {
    return WeekDialogState(this.selected);
  }
}

class WeekDialogState extends State<WeekDialog> {
  List<String> listWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  List<int> selected = [];
  WeekDialogState(this.selected);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              children: getWeekItem(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> getWeekItem() {
    return listWeek.map((value) {
      int index = listWeek.indexOf(value);
      return CheckboxListTile(
        title: Text(value),
        value: selected.length == 0 ? false : selected[index] == 1,
        onChanged: (bool) => changeChecked(bool!, index),
      );
    }).toList();
  }

  changeChecked(bool isChecked, int index) {
    if (selected.length == 0) return;
    if (isChecked) {
      if (selected[index] == 0) {
        selected[index] = 1;
      }
    } else {
      if (selected[index] == 1) {
        selected[index] = 0;
      }
    }

    setState(() {});
  }
}
