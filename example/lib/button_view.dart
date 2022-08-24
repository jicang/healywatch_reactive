import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:healy_watch_sdk/healy_watch_sdk_impl.dart';

class ButtonView extends StatelessWidget {
  final String _text;
  final Function()? action;

  ButtonView(this._text, {required this.action});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DeviceConnectionState>(
        stream: HealyWatchSDKImplementation.instance.connectionStateStream(),
        initialData: DeviceConnectionState.connected,
        builder: (c, snapshot) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: ElevatedButton(
                style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all(Color(0xFFffffff)),
                    backgroundColor:
                        MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey; // Disabled color
                      }
                      return Colors.blue; // Regular color
                    })),
                child: Text(_text),
                onPressed: (snapshot.data == DeviceConnectionState.connected)
                    ? action
                    : null,
              ),
            ),
          );
        });
  }
}
