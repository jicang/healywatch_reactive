import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter_plugin/flutter_plugin.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';
import 'package:healy_watch_sdk/util/shared_pref.dart';
import 'package:provider/provider.dart';

import '../LoadingDialog.dart';
import '../button_view.dart';
import '../main.dart';
import 'HistoryDataPage.dart';

class DeviceDetail extends StatefulWidget {
  String? deviceName;
  String? deviceId;

  DeviceDetail(this.deviceName, this.deviceId);

  @override
  State<StatefulWidget> createState() {
    return DeviceDetailState(deviceName, deviceId);
  }
}

class DeviceDetailState extends State<DeviceDetail> {
  String? deviceName;
  String? deviceId;

  DeviceDetailState(this.deviceName, this.deviceId);

  @override
  void dispose() {
    super.dispose();
    debugPrint("dispose");
    HealyWatchSDKImplementation.instance.disconnectDevice();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: ListTile(
              title: Text(
                deviceName!,
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
              subtitle: Text(deviceId!),
            ),
          ),
          body: Center(
            child: Column(
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: ElevatedButton(
                          style: ButtonStyle(
                              foregroundColor:
                                  MaterialStateProperty.all(Color(0xFFffffff)),
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                      (states) {
                                if (states.contains(MaterialState.disabled)) {
                                  return Colors.grey; // Disabled color
                                }
                                return Colors.blue; // Regular color
                              })),
                          child: Text("UnPair"),
                          onPressed: () => unPair(),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.0),
                  child: StreamBuilder<DeviceConnectionState>(
                    stream: HealyWatchSDKImplementation.instance
                        .connectionStateStream(),
                    initialData: DeviceConnectionState.connecting,
                    builder: (c, status) => Row(
                      children: [
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: ElevatedButton(
                            style: ButtonStyle(
                                foregroundColor: MaterialStateProperty.all(
                                    Color(0xFFffffff)),
                                backgroundColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                        (states) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return Colors.grey; // Disabled color
                                  }
                                  return Colors.blue; // Regular color
                                })),
                            child: Text("Connect"),
                            onPressed:
                                (status.data == DeviceConnectionState.connected)
                                    ? null
                                    : () => connected(),
                          ),
                        )),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: ElevatedButton(
                              style: ButtonStyle(
                                foregroundColor: MaterialStateProperty.all(
                                  Color(0xFFffffff),
                                ),
                                backgroundColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                  (states) {
                                    if (states
                                        .contains(MaterialState.disabled)) {
                                      return Colors.grey; // Disabled color
                                    }
                                    return Colors.blue; // Regular color
                                  },
                                ),
                              ),
                              child: Text("Disconnect"),
                              onPressed: (status.data ==
                                      DeviceConnectionState.connected)
                                  ? () => HealyWatchSDKImplementation.instance
                                      .disconnectDevice()
                                  : null,
                            ),
                          ),
                        )
                      ],
                    ),
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
        ),
        onWillPop: () async {
          bool? isExists = await onBackPressed();
          return isExists == null ? false : isExists;
        });
  }

  Future<bool?> onBackPressed() {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return getDialog();
      },
    );
  }
  static void _callback(NotificationEvent evt) {
    debugPrint("send evt to ui: $evt");
    final SendPort? send = IsolateNameServer.lookupPortByName("_listener_");
    if (send == null) debugPrint("can't find the sender");
    send?.send(evt);
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
    //selected = BleSdk.generateValue(list.length);
  }
  init() async {
    NotificationsListener.initialize(callbackHandle: _callback);

    var device=await SharedPrefUtils.getConnectedDevice();
    if(device!=null){
      connected();
    }


  }
  Widget getDialog() {
    return new AlertDialog(
      title: Container(
        width: MediaQuery.of(context).size.width,
        child: Text("Exists"),
      ),
      content: Text("Are you sure exists?"),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            exitApp();
          },
          child: Text("Confirm"),
        ),
        FlatButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text("Cancel"),
        ),
      ],
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

    return StreamBuilder<DeviceConnectionState>(
      stream: HealyWatchSDKImplementation.instance.connectionStateStream(),
      initialData: null,
      builder: (c, snapshot) => ElevatedButton(
        style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(Color(0xFFffffff)),
            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.disabled)) {
                return Colors.grey; // Disabled color
              }
              return Colors.blue; // Regular color
            })),
        child: Text(value.toString()),
        onPressed: (snapshot.data == DeviceConnectionState.connected)
            ? () =>
                index < 3 ? itemClick(listRoute[index]) : itemClickName(value)
            : null,
      ),
    );
  }

  void itemClick(String value) {
    //getPairedDevice();

    Navigator.pushNamed(context, value);
  }

  void itemClickName(String value) {
    Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) {
          return HistoryDataPage(value);
        },
      ),
    );
  }

  StreamSubscription? streamSubscription;

  connected() async {
    showLoading(context);
    await HealyWatchSDKImplementation.instance
        .reconnectDevice(autoReconnect: true);
    streamSubscription?.cancel();
    streamSubscription = HealyWatchSDKImplementation.instance
        .connectionStateStream()
        .listen((connectionState) {
      if (connectionState == DeviceConnectionState.connected) {
        disMiss();
      } else if (connectionState == DeviceConnectionState.disconnected) {
        disMiss();
      }
    });
  }

  LoadingDialog? loadingDialog = LoadingDialog("Connecting...");

  void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        loadingDialog = LoadingDialog("Connecting...");
        return loadingDialog!;
      },
    );
  }

  void disMiss() {
    if (loadingDialog == null) return;
    if (mounted) {
      Navigator.of(context).pop(loadingDialog);
      loadingDialog = null;
    }
  }

  unPair() async {
     await SharedPrefUtils.clearConnectedDevice();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ScanDeviceWidget(),
      ),
      (route) => false,
    );
  }
  MethodChannel methodChannel=new MethodChannel("pairedDevice");
  getPairedDevice() async{


    var device=await SharedPrefUtils.getConnectedDevice();
    var isBind=await FlutterPlugin.isBind(device!.id);
    if(device!=null&&isBind){

    }

    debugPrint("${isBind}");
      //methodChannel.invokeMethod("paired");
  }

  void exitApp() async{
    await HealyWatchSDKImplementation.instance.disconnectDevice();
    Navigator.pop(context, true);
  }
}
