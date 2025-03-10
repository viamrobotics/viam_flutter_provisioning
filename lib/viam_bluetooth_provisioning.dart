import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:blev/ble.dart';
import 'package:blev/ble_central.dart';
export 'package:blev/ble_central.dart';

class ViamBluetoothProvisioning {
  /// xxxx1111-... is the encompassing bluetooth service
  static final _bleServicePrefix = RegExp(r'^[0-9a-f]{4}1111', caseSensitive: false);

  /// xxxx2222-... is the write-only characteristic for SSID
  static final _ssidCharacteristicPrefix = RegExp(r'^[0-9a-f]{4}2222', caseSensitive: false);

  /// xxxx3333-... is the write-only characteristic for passkey
  static final _passkeyCharacteristicPrefix = RegExp(r'^[0-9a-f]{4}3333', caseSensitive: false);

  /// xxxx4444-... is the write-only characteristic for part ID
  static final _partIdCharacteristicPrefix = RegExp(r'^[0-9a-f]{4}4444', caseSensitive: false);

  /// xxxx5555-... is the write-only characteristic for part secret
  static final _partSecretCharacteristicPrefix = RegExp(r'^[0-9a-f]{4}5555', caseSensitive: false);

  /// xxxx6666-... is the write-only characteristic for app address
  static final _appAddressCharacteristicPrefix = RegExp(r'^[0-9a-f]{4}6666', caseSensitive: false);

  /// xxxx7777-... is the read-only characteristic for nearby available WiFi networks that the machine has detected
  static final _networkListCharacteristicPrefix = RegExp(r'^[0-9a-f]{4}7777', caseSensitive: false);

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

  // TODO: can/will convert to only scan for peripherials with the matching service UUIDs
  Stream<DiscoveredBlePeripheral> scanForPeripherals({List<String> serviceIds = const []}) {
    if (_ble == null) {
      throw Exception('Bluetooth is not initialized');
    }
    if (!_isPoweredOn) {
      throw Exception('Bluetooth is not powered on'); // re-init?
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

  static Future<List<String>> readNetworkList(ConnectedBlePeripheral peripheral) async {
    final bleService = peripheral.services.firstWhere((service) => _bleServicePrefix.hasMatch(service.id));

    final networkListCharacteristic = bleService.characteristics.firstWhere((char) => _networkListCharacteristicPrefix.hasMatch(char.id));
    final networkListBytes = await networkListCharacteristic.read();
    if (networkListBytes != null) {
      return _convertNetworkListBytes(networkListBytes);
    }
    return []; // could throw if null
  }

  static Future<void> writeNetworkConfig(
    ConnectedBlePeripheral peripheral,
    String ssid,
    String pw,
  ) async {
    final bleService = peripheral.services.firstWhere((service) => _bleServicePrefix.hasMatch(service.id));

    final ssidCharacteristic = bleService.characteristics.firstWhere((char) => _ssidCharacteristicPrefix.hasMatch(char.id));
    await ssidCharacteristic.write(utf8.encode(ssid));

    final passkeyCharacteristic = bleService.characteristics.firstWhere((char) => _passkeyCharacteristicPrefix.hasMatch(char.id));
    await passkeyCharacteristic.write(utf8.encode(pw));
  }

  static Future<void> writeRobotPartConfig(
    ConnectedBlePeripheral peripheral,
    String partId,
    String secret,
    String appAddress,
  ) async {
    final bleService = peripheral.services.firstWhere((service) => _bleServicePrefix.hasMatch(service.id));

    final partIdCharacteristic = bleService.characteristics.firstWhere((char) => _partIdCharacteristicPrefix.hasMatch(char.id));
    await partIdCharacteristic.write(utf8.encode(partId));

    final partSecretCharacteristic = bleService.characteristics.firstWhere((char) => _partSecretCharacteristicPrefix.hasMatch(char.id));
    await partSecretCharacteristic.write(utf8.encode(secret));

    final appAddressCharacteristic = bleService.characteristics.firstWhere((char) => _appAddressCharacteristicPrefix.hasMatch(char.id));
    await appAddressCharacteristic.write(utf8.encode(appAddress));
  }

  // Helper functions

  static List<String> _convertNetworkListBytes(Uint8List bytes) {
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
