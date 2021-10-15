import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingDialog extends Dialog {
  String msg;
  LoadingDialog(this.msg);
  @override
  Widget build(BuildContext context) {
    return Material(
        type: MaterialType.transparency,
        child: Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: Container(
              decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  )),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      msg,
                      style: TextStyle(color: Colors.black),
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
