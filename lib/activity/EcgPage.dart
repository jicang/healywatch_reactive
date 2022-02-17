import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';
import 'package:healy_watch_sdk/data_util.dart';

import '../button_view.dart';

class EcgPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return EcgPageState();
  }
}

class EcgPageState extends State<EcgPage> {
  TextEditingController _userAgeController = TextEditingController();

  List<FlSpot> listFlSpot = [FlSpot(0, 0)];

  bool onlyPPG = false;

  @override
  Widget build(BuildContext context) {
    if (listFlSpot.length == 0) listFlSpot = [FlSpot(0, 0)];
    return Scaffold(
      appBar: AppBar(
        title: Text("Ecg"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: "Duration"),
                    textAlign: TextAlign.center,
                    controller: _userAgeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                ButtonView(
                  "EnableEcg",
                  action: () => enableEcg(true),
                ),
                ButtonView(
                  "StopEcg",
                  action: () => enableEcg(false),
                )
              ],
            ),
            SwitchListTile(
              title: Text("OnlyPPG"),
              onChanged: (bool) => _enableOnlyPPg(bool),
              value: onlyPPG,
            ),
            Expanded(
              flex: 1,
              child: Text(ecgQuantity),
            ),
            Expanded(
              child: Container(
                child: LineChart(LineChartData(
                    borderData: FlBorderData(
                        border: const Border(
                            bottom: BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ))),
                    maxY: 2000,
                    minY: -2000,
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        spots: listFlSpot,
                        barWidth: 1,
                        dotData: FlDotData(
                          show: false,
                        ),
                      ),
                    ])),
              ),
            )
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

  String ecgQuantity = "";
  List<int> showPPGList = [];
  double maxPPG = 0;
  double minPPG = 8000;

  String getReasonInfo(HealyEcgFailureDataFailedCode errorCode) {
    String reasonInfo = "";
    switch (errorCode) {
      case HealyEcgFailureDataFailedCode.measurementNotTurned:
        reasonInfo = "空闲状态还没有开启过测量.";
        break;
      case HealyEcgFailureDataFailedCode.measurementInProgress:
        reasonInfo = "测量进行中.";
        break;
      case HealyEcgFailureDataFailedCode.measurementTimeout:
        reasonInfo = "测量超时，已经自动关闭.";
        break;
      case HealyEcgFailureDataFailedCode.lowPower:
        reasonInfo = "因为低电关闭.";
        break;
      case HealyEcgFailureDataFailedCode.charge:
        reasonInfo = "因为充电关闭.";
        break;
      case HealyEcgFailureDataFailedCode.manualClose:
        reasonInfo = "用户手动/App指令提前关闭.";
        break;
      case HealyEcgFailureDataFailedCode.restoreFactory:
        reasonInfo = "因为用于恢复出厂设置而关闭.";
        break;
      case HealyEcgFailureDataFailedCode.workOutMode:
        reasonInfo = "因为进入运动模式而关闭.";
        break;
      case HealyEcgFailureDataFailedCode.sosMode:
        reasonInfo = "因为进入SOS模式关闭.";
        break;
      case HealyEcgFailureDataFailedCode.weakSignal:
        reasonInfo = "ECG信号弱自动退出检测.";
        break;
      case HealyEcgFailureDataFailedCode.leadShedding:
        reasonInfo = "导联脱落（皮肤离开金属片）.";
        break;
      case HealyEcgFailureDataFailedCode.leadConnection:
        reasonInfo = "导联连接（皮肤重新接触金属片）.";
        break;

      case HealyEcgFailureDataFailedCode.doNotMove:
        reasonInfo = "提示测量中请不要动.";
        break;
    }
    return reasonInfo;
  }

  enableEcg(bool enable) async {
    String duration = _userAgeController.text;
    int durationInt = 0;
    if (!isEmpty(duration)) durationInt = int.parse(duration);
    if (enable) {
      Stream<HealyBaseMeasuremenetData> healyBaseMeasuremenetData =onlyPPG?HealyWatchSDKImplementation.instance
          .startOnlyPPGMessuringWithDuration(durationInt):
          HealyWatchSDKImplementation.instance
              .startEcgMessuringWithDuration(durationInt);
      healyBaseMeasuremenetData.listen((event) {
        if (event is HealyECGQualityData) {
          var hrv = event.hrvValue;
          var heart = event.heartRate;
          var ecgQ = event.ecgQuantity;
          ecgQuantity = "Hrv: $hrv\n"
              "HeartRate: $heart\n"
              "ECGQuantity: $ecgQ";
          setState(() {});
        } else if (event is HealyECGData) {
          List<int> ppgList = event.values;
          ppgList.forEach((value) {
            if (showPPGList.length >= 1200) showPPGList.removeAt(0);
            showPPGList.add(value);
          });
          listFlSpot.clear();

          setState(() {
            final filteredData = DataUtil.filterEcgData(showPPGList);
            for (int i = 0; i < filteredData.length; i++) {
              FlSpot flSpot = FlSpot(i.toDouble(), filteredData[i]);
              listFlSpot.add(flSpot);
            }
            print(listFlSpot.length);
          });
        } else if (event is HealyPPGData) {
          print("HealyPPGData");
        } else if (event is HealyEnterEcgData) {
          EnterEcgResultCode ecgResultCode = event.ecgResultCode;
          print("${ecgResultCode.index}");
        } else if (event is HealyEcgSuccessData) {
          String data = getHrvShowText(event);
          showMsgDialog(context, "EcgMeasureResult", data);
          listFlSpot.clear();
          showPPGList.clear();
        } else if (event is HealyEcgFailureData) {
          print(getReasonInfo(event.errorCode));
        }else if(event is HealyOnlyPPGFinish){
          print("HealyOnlyPPGFinish");
        }
      });
    } else {
      bool isSuccess =
          await HealyWatchSDKImplementation.instance.stopEcgMessuring();
      print("$isSuccess");
    }
  }

  String getHrvShowText(HealyEcgSuccessData healyEcgSuccessData) {
    String date = healyEcgSuccessData.dateTime.toString();
    int hrv = healyEcgSuccessData.hrvValue;
    int heart = healyEcgSuccessData.heartRate;
    int blood = healyEcgSuccessData.bloodValue;
    int tired = healyEcgSuccessData.tiredValue;
    int highBloodPressure = healyEcgSuccessData.hightBloodPressureValue;
    int lowBloodPressure = healyEcgSuccessData.lowBloodPressureValue;
    int moodValue = healyEcgSuccessData.moodValue;
    int breathRate = healyEcgSuccessData.breathRate;
    print("ppgLength${healyEcgSuccessData.ppgData.length}"
        " ecgLength${healyEcgSuccessData.ecgData.length}"
        " qualityPointsLength${healyEcgSuccessData.qualityPoints.length}");
    String showText = "Date:$date\n"
        "HrvScore:$hrv\n"
        "HeartRate:$heart\n"
        "BreathRate:$breathRate\n"
        "Blood:$blood\n"
        "Tired:$tired\n"
        "HighBloodPressure:$highBloodPressure\n"
        "LowBloodPressure:$lowBloodPressure\n"
        "MoodValue:$moodValue";
    return showText;
  }

  bool isEmpty(String value) {
    return null == value || value.length == 0;
  }
  _enableOnlyPPg(bool onlyPPG) {
    this.onlyPPG=onlyPPG;
    setState(() {

    });
  }
}


