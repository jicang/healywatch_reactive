import Flutter
import UIKit
import CoreBluetooth


public class SwiftFlutterPlugin: NSObject, Flutter.FlutterPlugin {
    var peripheral :CBPeripheral!
//    var peripheral = CBPeripheral()
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
      
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    
      if call.method == "getPaired" {
//          var teamJSON = call.arguments;
//          var teams:[String:Any] = teamJSON["deviceId"] as String
          let teamJSON:Dictionary = call.arguments as! Dictionary<String, Any>;

          let teams:String = teamJSON["deviceId"] as! String
          let isPeri = getPeripheral(idStr: teams)
          result(isPeri)
      } else if call.method == "getPlatformVersion" {
          result("iOS " + UIDevice.current.systemVersion)
      }
  }
    
    func getPeripheral (idStr:String) ->(Bool) {
        let centralManager = CBCentralManager()
//        let arr = centralManager.retrieveConnectedPeripherals(withServices: CBUUID.init(string: "fff0"))
        let arr = centralManager.retrieveConnectedPeripherals(withServices: [CBUUID.init(string: "fff0")]);
        
        if arr.count != 0 {
            peripheral = arr[0];
            let uuidStr = peripheral.identifier.uuidString
        }
        
        let uuid = UUID.init(uuidString: idStr);
        let arr2 = centralManager.retrievePeripherals(withIdentifiers: [uuid!]);
        
        if arr2.count == 0 {
            return true
        } else {
            for pripheralID in arr2 {
                let uuidStr = pripheralID.identifier.uuidString
                if idStr.isEqual(uuidStr) {
                    return true
                }
            }
            return true
        }
//        let mybool = arr2.count != 0;
//        return mybool
//        print("arrarrarr --- :",arr2)
        
    }
//    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral] {
}
