import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:blev/ble.dart';
import 'package:blev/ble_central.dart';
export 'package:blev/ble_central.dart';
import 'package:uuid/uuid.dart';

import 'wifi_network.dart';

class ViamBluetoothProvisioning {
  static final _uuidNamespace = '74a942f4-0f45-43f4-88ca-f87021ae36ea';
  static final _serviceNameKey = 'viam-provisioning';
  static final _availableWiFiNetworksKey = 'networks';
  static final _ssidKey = 'ssid';
  static final _pskKey = 'passkey';
  static final _robotPartIDKey = 'id';
  static final _robotPartSecretKey = 'secret';
  static final _appAddressKey = 'app_address';

  BleCentral? _ble;
  bool _isPoweredOn = false;

  final String _serviceUUID;
  final String _availableWiFiNetworksUUID;
  final String _ssidUUID;
  final String _pskUUID;
  final String _robotPartUUID;
  final String _robotPartSecretUUID;
  final String _appAddressUUID;

  factory ViamBluetoothProvisioning() {
    final uuid = Uuid();
    return ViamBluetoothProvisioning._(
      uuid.v5(_uuidNamespace, _serviceNameKey),
      uuid.v5(_uuidNamespace, _availableWiFiNetworksKey),
      uuid.v5(_uuidNamespace, _ssidKey),
      uuid.v5(_uuidNamespace, _pskKey),
      uuid.v5(_uuidNamespace, _robotPartIDKey),
      uuid.v5(_uuidNamespace, _robotPartSecretKey),
      uuid.v5(_uuidNamespace, _appAddressKey),
    );
  }
  ViamBluetoothProvisioning._(
    this._serviceUUID,
    this._availableWiFiNetworksUUID,
    this._ssidUUID,
    this._pskUUID,
    this._robotPartUUID,
    this._robotPartSecretUUID,
    this._appAddressUUID,
  );

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

  /// Scans for peripherals with the Viam bluetooth provisioning service UUID
  Stream<DiscoveredBlePeripheral> scanForPeripherals() {
    if (_ble == null) {
      throw Exception('Bluetooth is not initialized');
    }
    if (!_isPoweredOn) {
      throw Exception('Bluetooth is not powered on');
    }
    return _ble!.scanForPeripherals([_serviceUUID]);
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

  Future<List<WifiNetwork>> readNetworkList(ConnectedBlePeripheral peripheral) async {
    final bleService = peripheral.services.firstWhere((service) => service.id == _serviceUUID);

    final networkListCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _availableWiFiNetworksUUID);
    final networkListBytes = await networkListCharacteristic.read();
    if (networkListBytes != null) {
      return convertNetworkListBytes(networkListBytes);
    }
    return [];
  }

  Future<void> writeNetworkConfig(
    ConnectedBlePeripheral peripheral,
    String ssid,
    String pw,
  ) async {
    final bleService = peripheral.services.firstWhere((service) => service.id == _serviceUUID);

    final ssidCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _ssidUUID);
    await ssidCharacteristic.write(utf8.encode(ssid));

    final pskCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _pskUUID);
    await pskCharacteristic.write(utf8.encode(pw));
  }

  Future<void> writeRobotPartConfig(
    ConnectedBlePeripheral peripheral,
    String partId,
    String secret,
    String appAddress,
  ) async {
    final bleService = peripheral.services.firstWhere((service) => service.id == _serviceUUID);

    final partIdCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _robotPartUUID);
    await partIdCharacteristic.write(utf8.encode(partId));

    final partSecretCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _robotPartSecretUUID);
    await partSecretCharacteristic.write(utf8.encode(secret));

    final appAddressCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _appAddressUUID);
    await appAddressCharacteristic.write(utf8.encode(appAddress));
  }

  // Helper functions

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
