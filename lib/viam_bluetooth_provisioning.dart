import 'dart:async';

import 'package:blev/ble.dart';
import 'package:blev/ble_central.dart';

class ViamBluetoothProvisioning {
  BleCentral? _ble;
  bool _isPoweredOn = false;

  ViamBluetoothProvisioning();

  Future<void> initialize({Function(bool)? poweredOn}) async {
    _ble = await BleCentral.create();
    _ble?.getState().listen((state) {
      if (state == AdapterState.poweredOn) {
        _isPoweredOn = true;
        poweredOn?.call(true);
      } else {
        _isPoweredOn = false;
        poweredOn?.call(false);
      }
    });
  }

  Stream<DiscoveredBlePeripheral> scanForDevices({List<String> serviceIds = const []}) {
    if (_ble == null) {
      throw Exception('Bluetooth is not initialized');
    }
    if (!_isPoweredOn) {
      throw Exception('Bluetooth is not powered on');
    }
    return _ble!.scanForPeripherals(serviceIds);
  }

  // TODO: connect
  // TODO: read network list (and display on screen)
  // TODO: write ssid,pw,secret,part-id
}
