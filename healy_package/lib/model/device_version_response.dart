import 'firmware_data.dart';

class DeviceVersionResponse {
   int ?msgCode;
   String? msgInfo;
   FirmwareData? firmwareData;

  DeviceVersionResponse(this.msgCode, this.msgInfo, this.firmwareData);

  DeviceVersionResponse.fromJson(Map<String, dynamic> json) {
    msgCode = json['msgCode'] as int;
    msgInfo = json['msgInfo'] as String;
    if(json['data']==null){
      firmwareData=null;
    }else{
      firmwareData =
          FirmwareData.fromJson(json['data'] as Map<String, dynamic>);
    }

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['msgCode'] = msgCode;
    data['msgInfo'] = msgInfo;
    if (firmwareData != null) {
      data['data'] = firmwareData!.toJson();
    }
    return data;
  }
}
