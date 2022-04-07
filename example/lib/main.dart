import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';
import 'package:healy_watch_sdk/model/models.dart';
import 'package:healy_watch_sdk/util/bluetooth_conection_util.dart';
import 'package:healy_watch_sdk/util/shared_pref.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'activity/DeviceDetail.dart';
import 'activity/DeviceSettingPage.dart';
import 'activity/EcgPage.dart';
import 'activity/UserInfo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  toRunMyapp();
}

toRunMyapp() async {
  HealyWatchSDKImplementation healyWatchSDKImplementation =
      HealyWatchSDKImplementation.instance;
  BluetoothConnectionUtil bluetoothConnectionUtil =
      healyWatchSDKImplementation.bluetoothUtil;
  final ble = bluetoothConnectionUtil.bleManager;
  runApp(MultiProvider(
    providers: [
      Provider.value(value: ble),
      StreamProvider.value(value: ble.connectedDeviceStream, initialData: null)
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      routes: <String, WidgetBuilder>{
        "/scan": (context) => ScanDeviceWidget(),
        "/Basic": (context) => UserInfo(),
        "/ECG": (context) => EcgPage(),
        "/DeviceSetting": (context) => DeviceSettingPage(),
      },
      initialRoute: "/scan",
    );
  }
}

class ScanDeviceWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new ScanDeviceWidgetState();
  }
}

class ScanDeviceWidgetState extends State<ScanDeviceWidget> {
  bool isResume = true;
  String? deviceId;

  @override
  void initState() {
    super.initState();
    toDetailPage();
  }

  toDetailPage() async {
    final device = await SharedPrefUtils.getConnectedDevice();
    if (device != null) {
      deviceId = device.id;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => DeviceDetail(device.name, device.id),
        ),
        (route) => false,
      );
    }
  }

  // bool filterDevice(ScanResult scanResult) {
  //   bool isHealyDevice = false;
  //   String name = scanResult.peripheral.name;
  //   if (name.isNotEmpty && name.toLowerCase().contains("healy")) {
  //     return true;
  //   }
  //   return isHealyDevice;
  // }

  List<ScanResult> listDevice = [];
  late Stream deviceListStream;

  @override
  Widget build(BuildContext context) {
    print("build deviceId $deviceId");
    final results = deviceId == null
        ? StreamBuilder<List<DiscoveredDevice>>(
            stream: HealyWatchSDKImplementation.instance
                .scanResults(),
            initialData: [],
            builder: (c, snapshot) => ListView(
              children: ListTile.divideTiles(
                      context: context,
                      tiles: snapshot.data!.map((peripheral) {
                        return ListTile(
                          title: Text(peripheral.name.isEmpty
                              ? "Unknwon Device"
                              : peripheral.name),
                          subtitle: Text(peripheral.id.toString()),
                          trailing: Text(peripheral.rssi.toString()),
                          onTap: () => _connected(peripheral),
                        );
                      }),
                      color: Colors.red)
                  .toList(),
            ),
          )
        : SizedBox();
    // final connectedDevice = StreamBuilder<List<Peripheral>>(
    //   stream: Stream.periodic(Duration(seconds: 1))
    //       .where((event) => isResume)
    //       .asyncMap(
    //           (_) => HealyWatchSDKImplementation.instance.getConnectedDeviceUnsafe()),
    //   initialData: [],
    //   builder: (c, snapshot) => Column(
    //     children: snapshot.data
    //         .map((d) => ListTile(
    //               title: Text(d.name),
    //               subtitle: Text(d.id.toString()),
    //               trailing: StreamBuilder<BluetoothDeviceState>(
    //                 stream: d.state,
    //                 initialData: BluetoothDeviceState.disconnected,
    //                 builder: (c, snapshot) {
    //                   if (snapshot.data == BluetoothDeviceState.connected) {
    //                     return RaisedButton(
    //                       child: Text('OPEN'),
    //                       onPressed: () => _connected(d),
    //                     );
    //                   }
    //                   return Text(snapshot.data.toString());
    //                 },
    //               ),
    //             ))
    //         .toList(),
    //   ),
    // );

    return Scaffold(
      appBar: AppBar(
        title: Text("DeviceList"),
        actions: <Widget>[],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              onPressed: () => toStartScan(),
              child: const Text("StartScan"),
            ),
            Expanded(
              child: results,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> toStartScan() async {
    BleStatus bluetoothState =
        await HealyWatchSDKImplementation.instance.getBluetoothState();
    if (bluetoothState == BleStatus.poweredOff) {
      // _scaffoldKey.currentState!.showSnackBar(snackBar);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('BluetoothState is off')));
      return;
    }
    print("scan");
    if (Platform.isAndroid) {
      bool isGranted = await Permission.location.request().isGranted;

      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt! > 30) {
        isGranted = isGranted
            ? await Permission.bluetoothScan.request().isGranted
            : isGranted;
        isGranted = isGranted
            ? await Permission.bluetoothConnect.request().isGranted
            : isGranted;
      }

      if (isGranted) {
        startScan();
      } else {
        final bool isPermanentlyDenied =
            await Permission.location.isPermanentlyDenied;
        if (isPermanentlyDenied) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return getDialog(Permission.location.toString());
            },
          );
        }
      }
    } else {
      startScan();
    }
  }

  void startScan() {
    listDevice.clear();
    setState(() {});
    HealyWatchSDKImplementation.instance.scanResults();
  }

  void stopScan() {
    HealyWatchSDKImplementation.instance.cancelScanningDevices();
  }

  Widget getDialog(String permissionName) {
    return AlertDialog(
      title: Text("PermissionRequest"),
      content: Text("$permissionName权限已经被拒绝，是否现在开启"),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("取消"),
        ),
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
            openAppSettings();
          },
          child: Text("确认"),
        ),
      ],
    );
  }

  _connected(DiscoveredDevice device) async {
    // HealyWatchSDKImplementation.instance.cancelScanningDevices();
    final healyDevice = HealyDevice(id: device.id, name: device.name);
    stopScan();
    HealyWatchSDKImplementation.instance.connectDevice(healyDevice);

    await SharedPrefUtils.setConnectedDevice(healyDevice);

    // isResume = false;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DeviceDetail(device.name, device.id),
      ),
      (route) => false,
    );
    // await Navigator.push<void>(
    //     context,
    //     MaterialPageRoute(
    //         builder: (_) => DeviceDetail(device.name, device.id)));
    // ;
    // isResume = true;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    // HealyWatchSDKImplementation.instance.cancelScanningDevices();
    //  HealyWatchSDKImplementation.instance.disconnectDevice();
  }
}
