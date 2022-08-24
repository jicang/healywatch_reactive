import 'dart:developer';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';

import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';

import '../button_view.dart';

class FirmwareUpdatePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return FirmwareUpdatePageState();
  }
}

class FirmwareUpdatePageState extends State<FirmwareUpdatePage> {
  double dfuPercent = 2 / 3;
  bool isDfuMode = false;
  String _downloadUrl = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FirmwareUpdate"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                ButtonView(
                  "CheckFirmwareVersion",
                  action: () async {
                    // final String currentVersion =
                    //     await HealyWatchSDKImplementation.instance
                    //         .getFirmwareVersion();
                    var connectivityResult =
                        await (Connectivity().checkConnectivity());
                    if (connectivityResult == ConnectivityResult.none) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Network unavailable'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ));
                      return;
                    }
                    final String? downloadUrl =
                        await HealyWatchSDKImplementation.instance
                            .checkIfFirmwareUpdateAvailable('0.0.0');

                    if (downloadUrl != null) {
                      setState(() {
                        _downloadUrl = downloadUrl;
                      });
                      log('Firmware Update available');
                    } else {
                      debugPrint('already lastVersion');
                    }
                  },
                ),
                ButtonView(
                  "RunFirmwareUpdate",
                  action: () async {
                    if (_downloadUrl.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('LastVersion has already'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ));
                      return;
                    }
                    HealyWatchSDKImplementation.instance
                        .downloadLatestFirmwareUpdate(_downloadUrl)
                        .listen((event) {
                      isDfuMode = true;
                      dfuPercent = (event * 3 - 2) * 100;
                      setState(() {});
                    }, onError: (msg) {
                      debugPrint("dfu error $msg");
                    }, onDone: () {
                      debugPrint("dfu onDone");
                    });
                  },
                ),
                /* ButtonView(
                  "CheckResUpdate",
                  action: () => null,
                ), */
              ],
            ),
            Text(_downloadUrl.isNotEmpty
                ? "Firmware Update available: $_downloadUrl"
                : "No Firmware Update available"),
            Visibility(
              visible: isDfuMode,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        value: dfuPercent / 100,
                        backgroundColor: Colors.grey,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text("${dfuPercent.toInt()}%"),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
