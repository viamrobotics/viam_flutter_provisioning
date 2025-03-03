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

  Stream<DiscoveredBlePeripheral> scanForPeripherals({List<String> serviceIds = const []}) {
    if (_ble == null) {
      throw Exception('Bluetooth is not initialized');
    }
    if (!_isPoweredOn) {
      throw Exception('Bluetooth is not powered on');
    }
    return _ble!.scanForPeripherals(serviceIds);
  }

  Future<ConnectedBlePeripheral> connectToPeripheral(DiscoveredBlePeripheral peripheral) async {
    if (_ble == null) {
      throw Exception('Bluetooth is not initialized');
    }
    if (!_isPoweredOn) {
      throw Exception('Bluetooth is not powered on');
    }
    return await _ble!.connectToPeripheral(peripheral.id);
  }

  Future<void> readNetworkList(ConnectedBlePeripheral peripheral) async {
    // TODO: use knowledge of services/charactericts to read network list + return model that can be displayed
    // find service with id..
    // find characteristic with id..
    // read characteristic and convert bytes to string, then parse into models
  }

  Future<void> writeNetworkConfig(
    ConnectedBlePeripheral peripheral,
    String ssid,
    String pw,
  ) async {
    // TODO: ..
  }

  // TODO: secret + part-id here in separate method?
}
