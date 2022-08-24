import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';

import '../button_view.dart';

class UserInfo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return UserInfoState();
  }
}

class UserInfoState extends State<UserInfo> {
  HealyGender gender = HealyGender.male;

  TextEditingController _userAgeController = TextEditingController();
  TextEditingController _userHeightController = TextEditingController();
  TextEditingController _userWeightController = TextEditingController();
  TextEditingController _userStrideController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("UserInfo"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                ButtonView(
                  "SetTime",
                  action: () => setTime(),
                ),
                ButtonView(
                  "GetTime",
                  action: () => getTime(),
                )
              ],
            ),
            Text(
              "Basic Infomation Set",
              style: TextStyle(color: Colors.grey),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("Male"),
                Radio(
                  value: HealyGender.male,
                  groupValue: gender,
                  onChanged: (HealyGender? value) => setGenderValue(value),
                ),
                Text("Female"),
                Radio(
                  value: HealyGender.female,
                  groupValue: gender,
                  onChanged: (HealyGender? value) => setGenderValue(value),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Age"),
                    textAlign: TextAlign.center,
                    controller: _userAgeController,
                    onSubmitted: (value) => textSaved(value),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Height"),
                    textAlign: TextAlign.center,
                    controller: _userHeightController,
                    onSubmitted: (value) => textSaved(value),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(labelText: "Weight"),
                    controller: _userWeightController,
                    onSubmitted: (value) => textSaved(value),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: TextField(
                    enabled: false,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(labelText: "Stride"),
                    controller: _userStrideController,
                    onSubmitted: (value) => textSaved(value),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                ButtonView(
                  "SetUserInfo",
                  action: () => setUserInfo(),
                ),
                ButtonView(
                  "GetUserInfo",
                  action: () => getUserInfo(),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> getItemList() {
    List<int> list = List.generate(16, (int index) {
      return index;
    });
    return list.map((value) {
      return getItemChild(value);
    }).toList();
  }

  Widget getItemChild(int value) {
    return ElevatedButton(
      child: Text(value.toString()),
      onPressed: () => itemClick(value),
    );
  }

  void itemClick(int value) {
    debugPrint("$value");
  }

  setGenderValue(HealyGender? value) {
    this.gender = value!;
    setState(() {});
  }

  textSaved(String value) {
    debugPrint(value);
  }

  Widget getDialog(BuildContext context, String dataType, String msg) {
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
        return getDialog(context, title, msg);
      },
    );
  }

  setUserInfo() async {
    if (isEmpty(_userAgeController.text) ||
        isEmpty(_userHeightController.text) ||
        isEmpty(_userWeightController.text) ||
        isEmpty(_userStrideController.text)) return;

    HealyUserInformation healyUserInformation = HealyUserInformation(
      gender: gender,
      age: int.parse(_userAgeController.text),
      heightInCm: double.parse(_userHeightController.text),
      weightInKg: double.parse(_userWeightController.text),
      stepLength: int.parse(_userStrideController.text),
    );

    bool isSetSuccess =
        await healyWatchSDK.setUserInformation(healyUserInformation);
    showMsgDialog(context, "healy", isSetSuccess.toString());
  }

  bool isEmpty(String value) {
    return value.length == 0;
  }

  getTime() async {
    DateTime dateTime = await healyWatchSDK.getDeviceTime();
    if (mounted) showMsgDialog(context, "healy", dateTime.toString());
  }

  setTime() async {
    HealySetDeviceTime dateTime =
        await healyWatchSDK.setDeviceTime(DateTime.now());
    showMsgDialog(context, "healy", dateTime.maxLength.toString());
  }

  getUserInfo() async {
    HealyUserInformation setPersonalInfo =
        await healyWatchSDK.getUserInformation();

    String age = setPersonalInfo.age.toString();
    String height = setPersonalInfo.heightInCm.toString();
    String weight = setPersonalInfo.weightInKg.toString();
    String strideLength = setPersonalInfo.stepLength.toString();
    this.gender = setPersonalInfo.gender;
    _userAgeController.text = age;
    _userHeightController.text = height;
    _userWeightController.text = weight;
    _userStrideController.text = strideLength;
    if (mounted) setState(() {});
  }
}
