import 'package:flutter/material.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';

import '../LoadingDialog.dart';
import '../button_view.dart';
import 'HistoryDataPage.dart';

class DeviceDetail extends StatefulWidget {
  final DiscoveredDevice device;

  DeviceDetail( this.device);

  @override
  State<StatefulWidget> createState() {
    return DeviceDetailState(device);
  }
}

class DeviceDetailState extends State<DeviceDetail> {
  late DiscoveredDevice device;

  DeviceDetailState(this.device);

  @override
  void dispose() {
    super.dispose();
    HealyWatchSDKImplementation.instance.disconnectDevice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          title: Text(
            device.name,
            style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
          ),
          subtitle: Text(device.id.toString()),
        ),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: <Widget>[
                  ButtonView(
                    "Connect",
                    action: () => connected(),
                  )
                ],
              ),
            ),
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
          ],
        ),
      ),
    );
  }

  List<String> listOp = [
    'Basic',
    'DeviceSetting',
    "ECG",
    HistoryDataPageState.PageAllData,
    HistoryDataPageState.PageDetailData,
    HistoryDataPageState.PageTotalData,
    HistoryDataPageState.PageStaticHrData,
    HistoryDataPageState.PageDynamicHrData,
    HistoryDataPageState.PageSleepData,
    HistoryDataPageState.PageExerciseData,
    HistoryDataPageState.PageHrvData,
  ];
  List<String> listRoute = ['/Basic', '/DeviceSetting', "/ECG"];

  List<Widget> getItemList() {
    return listOp.map((value) {
      return getItemChild(value);
    }).toList();
  }

  Widget getItemChild(String value) {
    int index = listOp.indexOf(value);

    return StreamBuilder<ConnectionStateUpdate>(
      stream: HealyWatchSDKImplementation.instance.connectionStateStream(),
      initialData: null,
      builder: (c, snapshot) => RaisedButton(
        color: Colors.blue,
        child: Text(value.toString()),
        textColor: Colors.white,
        onPressed: (snapshot.data?.connectionState ==
                DeviceConnectionState.connected)
            ? () =>
                index < 3 ? itemClick(listRoute[index]) : itemClickName(value)
            : null,
      ),
    );
  }

  void itemClick(String value) {
    Navigator.pushNamed(context, value);
  }

  void itemClickName(String value) {
    Navigator.push(context, new MaterialPageRoute(builder: (context) {
      return HistoryDataPage(value);
    }));
  }

  connected() async {
    showLoading(context);
    await HealyWatchSDKImplementation.instance.connectDevice(device);
    disMiss();
  }

   LoadingDialog ?loadingDialog;

  void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        if (loadingDialog == null) {
          return LoadingDialog("Connectting...");
        } else {
          return loadingDialog!;
        }
      },
    );
  }

  void disMiss() {
    Navigator.of(context).pop(loadingDialog);
  }
}
