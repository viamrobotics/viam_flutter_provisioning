import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:blev/ble.dart';
import 'package:blev/ble_central.dart';

// TODO: way to handle if device is using micro-rdk
class ViamBluetoothProvisioning {
  late BleCentral ble;
  bool isPoweredOn = false;

  // ASYNC init okay..?
  init() async {
    ble = await BleCentral.create();
    ble.getState().listen((state) {
      // switch..
      if (state == AdapterState.poweredOn) {
        isPoweredOn = true; // must be true to scan or connect..
      } else {
        isPoweredOn = false;
      }
    });
  }

  // TODO: NEXT - SCAN AND SHOW IN LIST!
  // take in optinal arg w/ default value of null or empty for device ids we scan for
  Stream<DiscoveredBlePeripheral> scanForDevicesAsStream() async* {
    final scanStream = ble.scanForPeripherals([]);
    await for (final device in scanStream) {
      yield device;
    }
  }

  // TODO: connect

  // TODO: read network list

  // TODO: write ssid,pw,secret,part-id
}
