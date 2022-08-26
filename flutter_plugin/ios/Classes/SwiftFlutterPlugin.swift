import Flutter
import UIKit
import CoreBluetooth

public class SwiftFlutterPlugin: NSObject, Flutter.FlutterPlugin {
    
    let HEALY_SERVICE_ID = "fff0"
    
    private var peripheral :CBPeripheral!
    private var centralManager: CBCentralManager!
    private var centralManagerDelegate: CentralManagerDelegate!
    
    public override init() {
        
        centralManagerDelegate = CentralManagerDelegate()
        centralManager = CBCentralManager(delegate: centralManagerDelegate, queue: nil)
        
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
      
        let channel = FlutterMethodChannel(name: "flutter_plugin", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
      
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

      if call.method == "getPaired" {
          
          let teamJSON:Dictionary = call.arguments as! Dictionary<String, Any>;
          let deviceId:String = teamJSON["deviceId"] as! String
          let isPeri = isPeripheralConnected(idStr: deviceId)
          result(isPeri)
      
      } else if call.method == "getPairedDevices" {
          
          let peripherals = getConnectedPeripherals()
          result(peripherals)
          
      } else if call.method == "getPlatformVersion" {

          result("iOS " + UIDevice.current.systemVersion)
          
      }
    }
    
    // Gets connected peripherals to the system.
    func getConnectedPeripherals () -> (Dictionary<String, String>?) {
        
        if !centralManagerDelegate.isPoweredOn {
            return nil
        }
        
        var peripherals = Dictionary<String, String>()
        
        let arr = centralManager.retrieveConnectedPeripherals(withServices: [CBUUID.init(string: HEALY_SERVICE_ID)])
        for peripheral in arr {
            peripherals[peripheral.identifier.uuidString] = peripheral.name
        }
        
        return peripherals
    }
    
    // Checks if the given device is connected to the system.
    func isPeripheralConnected (idStr:String) ->(Bool) {
             
        let peripherals = getConnectedPeripherals()
        return peripherals?.keys.contains(idStr) ?? false

    }
}

// MARK: - CBCentralManagerDelegate
// A protocol that provides updates for the discovery and management of peripheral devices.
final class CentralManagerDelegate: NSObject, CBCentralManagerDelegate {
    public var isPoweredOn = false
    
    // MARK: - Check
    func centralManagerDidUpdateState(_ central: CBCentralManager) {

      switch central.state {
          
        case .poweredOff:
          
          #if DEBUG
          print("Is Powered Off.")
          #endif
          
        case .poweredOn:
          
          #if DEBUG
          print("Is Powered On.")
          #endif
          
          isPoweredOn = true
          
        case .unsupported:
          
          #if DEBUG
          print("Is Unsupported.")
          #endif
          
        case .unauthorized:
          
          #if DEBUG
          print("Is Unauthorized.")
          #endif
          
        case .unknown:
          
          #if DEBUG
          print("Unknown")
          #endif
          
        case .resetting:
          
          #if DEBUG
          print("Resetting")
          #endif
          
        @unknown default:
          
          #if DEBUG
          print("Error")
          #endif
          
        }
    }
}
