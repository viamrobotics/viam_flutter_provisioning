part of '../viam_bluetooth_provisioning.dart';

class ViamBluetoothProvisioning {
  static Future<void> initialize({Function(bool)? poweredOn}) async {
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false);
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        poweredOn?.call(true);
      } else {
        poweredOn?.call(false);
      }
    });
  }

  /// Scans for peripherals with the Viam bluetooth provisioning service UUID
  static Future<Stream<List<ScanResult>>> scanForPeripherals() async {
    await FlutterBluePlus.startScan(withServices: [Guid(ViamBluetoothUUIDs.serviceUUID)]);
    return FlutterBluePlus.onScanResults;
  }

  static List<WifiNetwork> convertNetworkListBytes(Uint8List bytes) {
    int currentIndex = 0;
    final networks = <WifiNetwork>[];
    while (currentIndex < bytes.length) {
      final meta = bytes[currentIndex];
      final isSecure = (meta & 0x80) != 0;
      final signalStrength = meta & 0x7F;

      int nullIndex = currentIndex + 1;
      while (nullIndex < bytes.length && bytes[nullIndex] != 0) {
        nullIndex++;
      }
      final ssid = utf8.decode(bytes.sublist(currentIndex + 1, nullIndex));

      networks.add(WifiNetwork(
        ssid: ssid,
        signalStrength: signalStrength,
        isSecure: isSecure,
      ));
      currentIndex = nullIndex + 1;
    }
    return networks;
  }
}
