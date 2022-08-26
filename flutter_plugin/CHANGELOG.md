# Versions

## [0.0.2] - 2022-08-26
* Added `getPairedDevices` for iOS to get Healy watches that paired to the system.
* Renamed `getPeripheral` to `isPeripheralConnected` in SwiftFlutterPlugin.swift to match the purpose of this function.
* Fixed `isPeripheralConnected` function in SwiftFlutterPlugin.swift, where not connected peripheral returns connected. 