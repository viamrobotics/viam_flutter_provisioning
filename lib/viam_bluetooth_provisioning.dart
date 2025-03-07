import 'dart:async';
import 'dart:typed_data';

import 'package:blev/ble.dart';
import 'package:blev/ble_central.dart';

export 'package:blev/ble_central.dart';

class ViamBluetoothProvisioning {
  /// xxxx1111-... is the encompassing bluetooth service
  /// ex: 79ff1111-4f38-44b9-b3b5-78fb7e14757e
  static final _bleServicePrefix = RegExp(r'^[0-9a-f]{4}1111', caseSensitive: false);

  /// xxxx7777-... is the wifi network characteristic
  /// ex: a8ee7777-2496-485a-b0ea-dc63a1122f1
  static final _networkListCharacteristicPrefix = RegExp(r'^[0-9a-f]{4}2222', caseSensitive: false);

  BleCentral? _ble;
  bool _isPoweredOn = false;

  ViamBluetoothProvisioning();

  Future<void> initialize({Function(bool)? poweredOn}) async {
    _ble = await BleCentral.create();
    _ble?.getState().listen((state) {
      if (state == AdapterState.poweredOn) {
        _isPoweredOn = true;
      } else {
        _isPoweredOn = false;
      }
      poweredOn?.call(_isPoweredOn);
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

  Future<List<String>> readNetworkList(ConnectedBlePeripheral peripheral) async {
    for (final service in peripheral.services) {
      if (_bleServicePrefix.hasMatch(service.id)) {
        for (final characteristic in service.characteristics) {
          if (_networkListCharacteristicPrefix.hasMatch(characteristic.id)) {
            final networkListBytes = await characteristic.read();
            if (networkListBytes != null) {
              return _convertNetworkListBytes(networkListBytes);
            }
          }
        }
      }
    }
    return []; // could also throw if can't find
  }

  Future<void> writeNetworkConfig(
    ConnectedBlePeripheral peripheral,
    String ssid,
    String pw,
  ) async {
    // TODO: ..
  }

  Future<void> writeRobotPartConfig(
    ConnectedBlePeripheral peripheral,
    String secret,
    String partId,
    String appAddress, // maybe?
  ) async {
    // TODO: ..
  }

  // Helper functions

  List<String> _convertNetworkListBytes(Uint8List bytes) {
    // https://github.com/viamrobotics/agent/pull/77#issuecomment-2699307427
    //
    // ssid := "foobar"
    // signal := uint8(50) // can't be more than 127, use 0-100)
    // secure := true
    //
    // meta := byte(signal)
    // if secure {
    // 	meta = meta | (1 << 7)
    // }
    //
    // list := []byte{meta}
    // list = append(list, []byte(ssid)...)
    // list = append(list, 0x0) // separator/terminator
    //
    // fmt.Printf("HEX: % x\n", list)
    //
    // newMeta := list[0]
    // newSecure := uint8(newMeta) > 127
    // newSignal := newMeta &^ byte(1<<7)
    // newSsid := string(list[1:])

    // TODO: use above logic to parse out models, maybe return more than list, can return models
    return [];
  }
}
