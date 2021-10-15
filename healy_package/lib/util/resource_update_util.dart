import 'dart:io';

import '../bleconst/device_cmd.dart';
import '../healy_watch_sdk_impl.dart';
import 'ble_sdk.dart';

class ResourceUpdateUtil {
  String resFilePath;
  List<List<int>> byteList = [];
  int packageIndex = 0; //块(4096)编号

  late List<int> fileByte;
  late List<int> md5Byte;
  int maxLength;

  ResourceUpdateUtil(this.resFilePath,  this.maxLength) {
    final File binFile = File("$resFilePath/color565.bin");
    final File md5File = File("$resFilePath/color565MD5.txt");
    fileByte = binFile.readAsBytesSync();
    final String md5String = md5File.readAsStringSync();
    md5Byte = getMd5Byte(md5String.trim());
    final int dataLength = fileByte.length;
    final int length =
        dataLength % 4096 == 0 ? dataLength ~/ 4096 : dataLength ~/ 4096 + 1;
    for (int i = 0; i < length; i++) {
      //数据分块，一块4096长度
      final int start = i * 4096;
      int end = (i + 1) * 4096;
      if (end > fileByte.length) {
        end = fileByte.length;
      }
      final List<int> value = fileByte.sublist(start, end);
      byteList.add(value);
    }
  }
  List<int> getMd5Byte(String md5String) {
    final int length = md5String.length ~/ 2;
    final List<int> value = BleSdk.generateValue(length);
    for (int i = 0; i < length; i++) {
      final String s = md5String.substring(i * 2, i * 2 + 2);
      value[i] = int.parse(s, radix: 16) & 0xff;
    }
    return value;
  }

  List<int> getPackageData(int packageIndex) {
    return byteList[packageIndex];
  }

  List<int> checkAllFile(ResCmdMode resCmdMode) {
    final int length = fileByte.length;
    final int crc16 = calcCRC16(fileByte, fileByte.length);
    final List<int> value = BleSdk.generateValue(26);
    value[0] = DeviceCmd.resCheck;
    value[1] = resCmdMode == ResCmdMode.startCheck ? 1 : 2;
    value[2] = length & 0xff; //低位在前
    value[3] = (length >> 8) & 0xff;
    value[4] = (length >> 16) & 0xff;
    value[5] = (length >> 24) & 0xff;
    for (int i = 0; i < md5Byte.length; i++) {
      value[6 + i] = md5Byte[i];
    }
    value[22] = crc16 & 0xff;
    value[23] = (crc16 >> 8) & 0xff;
    final int crcValue16 = calcCRC16(value, 24);
    value[24] = crcValue16 & 0xff;
    value[25] = (crcValue16 >> 8) & 0xff;
    return value;
  }

  List<List<int>> getSendData(int packageIndex, int maxLength) {
    final List<int> packageByte = getPackageData(packageIndex);
    final int packageCrc = calcCRC16(packageByte, packageByte.length);
    final int packageByteLength = packageByte.length;
    bool isFinish = false;
    final List<List<int>> list = [];
    int count = 0;
    int length = maxLength;
    int sendTotalPackageLength = 0;
    while (sendTotalPackageLength < packageByteLength) {
      int sendDataLength = maxLength - 6;
      if (sendTotalPackageLength + sendDataLength > packageByteLength) {
        sendDataLength = packageByteLength - sendTotalPackageLength;
        if (sendDataLength + 8 > maxLength) {
          sendDataLength = sendDataLength + 8 - maxLength;
          length = sendDataLength + 6;
        } else {
          isFinish = true;
          length = sendDataLength + 8;
        }
      }
      final List<int> value = BleSdk.generateValue(length);
      value[0] = DeviceCmd.resDataSend;
      value[1] = packageIndex & 0xff;
      value[2] = packageIndex >> 8 & 255;
      value[3] = count;
      for (int i = 0; i < sendDataLength; i++) {
        value[i + 4] = packageByte[sendTotalPackageLength + i];
      }
      if (isFinish) {
        value[value.length - 4] = packageCrc & 0xff;
        value[value.length - 3] = (packageCrc >> 8) & 0xff;
      }
      final int crc16 = calcCRC16(value, value.length - 2);
      value[value.length - 2] = crc16 & 0xff;
      value[value.length - 1] = (crc16 >> 8) & 0xff;
      list.add(value);
      sendTotalPackageLength += sendDataLength;
      if (!isFinish) count++;
    }
    list.add(checkPackage(packageIndex, packageCrc));

    return list;
  }

  ///每块数据发送完成后请求检验数据正确性
  List<int> checkPackage(int package, int crc) {
    final List<int> value = BleSdk.generateValue(8);
    value[0] = DeviceCmd.resDataSend;
    value[1] = package & 0xff;
    value[2] = package >> 8 & 255;
    value[3] = 0xff;
    value[4] = crc & 0xff;
    value[5] = (crc >> 8) & 0xff;
    final int crc16 = calcCRC16(value, value.length - 2);
    value[6] = crc16 & 0xff;
    value[7] = (crc16 >> 8) & 0xff;
    return value;
  }

  int calcCRC16(List<int> pArray, int length) {
    int wCRC = 0xFFFF;
    int cRCCount = length;
    int i = 0;
    int num = 0;
    while (cRCCount > 0) {
      cRCCount--;
      wCRC = wCRC ^ (0xFF & pArray[num++]);
      for (i = 0; i < 8; i++) {
        if ((wCRC & 0x0001) == 1) {
          wCRC = wCRC >> 1 ^ 0xA001;
        } else {
          wCRC = wCRC >> 1;
        }
      }
    }
    return wCRC;
  }

  Future<void> sendFileByte({void Function(double) ?progressCallback}) async {
    for (int i = 0; i < byteList.length; i++) {
      final List<List<int>> sendValue = getSendData(i, maxLength);
      await sendData(sendValue);

      progressCallback?.call(i/byteList.length);
    }
    await HealyWatchSDKImplementation.instance
        .checkResUpdateData(checkAllFile(ResCmdMode.endCheck));
  }

  Future<void> sendData(List<List<int>> sendValue) async {
    final bool sendSuccess =
        await HealyWatchSDKImplementation.instance.sendResUpdateData(sendValue);
    if (!sendSuccess) sendData(sendValue);
  }
}

enum ResCmdMode {
  ///检测固件是否需要资源文件升级
  startCheck,

  ///升级资源文件的最后，检查资源文件的完整性
  endCheck
}
