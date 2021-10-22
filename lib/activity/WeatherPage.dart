

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';




import '../button_view.dart';


class WeatherPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return WeatherPageState();
  }
}

class WeatherPageState extends State<WeatherPage> {

  TextEditingController _userAgeController = TextEditingController();
  TextEditingController _weatherIdController = TextEditingController();
  TextEditingController _tempHighController = TextEditingController();
  TextEditingController _tempLowController = TextEditingController();
  TextEditingController _cityNameController = TextEditingController();
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Weather"),
      ),
      body: Padding(
        padding: EdgeInsets.only(left: 16, right: 16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                        labelText: "WeatherId", helperText: "(0-38)"),
                    textAlign: TextAlign.center,
                    controller: _weatherIdController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "TempNow"),
                    textAlign: TextAlign.center,
                    controller: _userAgeController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9-]"))
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "TempHigh"),
                    textAlign: TextAlign.center,
                    controller: _tempHighController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9-]"))
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "TempLow"),
                    textAlign: TextAlign.center,
                    controller: _tempLowController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9-]"))
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: "CityName"),
                    textAlign: TextAlign.center,
                    controller: _cityNameController,
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                ButtonView(
                  "SetWeather",
                  action: () => setWeather(),
                ),
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

  void showMsgDialog(BuildContext context, String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getDialog(title, msg);
      },
    );
  }


  setWeather() async{
    String tempNow = _userAgeController.text;
    String tempHigh = _tempHighController.text;
    String tempLow = _tempLowController.text;
    String cityName = _cityNameController.text;
    String weatherId = _weatherIdController.text;
    if (isEmpty(weatherId) ||
        isEmpty(tempNow) ||
        isEmpty(tempHigh) ||
        isEmpty(tempLow) ||
        isEmpty(cityName)) return;
    WeatherData weatherData = WeatherData();
    weatherData.cityName = cityName;
    weatherData.tempLow = int.parse(tempLow);
    weatherData.tempHigh = int.parse(tempHigh);
    weatherData.tempNow = int.parse(tempLow);
    weatherData.weatherId = int.parse(weatherId);
   bool isSet=await healyWatchSDK.setWeatherData(weatherData);
    showMsgDialog(context, "SetWeather", "$isSet");
  }

  bool isEmpty(String value) {
    return null == value || value.length == 0;
  }
}
