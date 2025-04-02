import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:blev/ble.dart';
import 'package:blev/ble_central.dart';
export 'package:blev/ble_central.dart';
import 'package:uuid/uuid.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';

import 'wifi_network.dart';

class ViamBluetoothProvisioning {
  static final _uuidNamespace = '74a942f4-0f45-43f4-88ca-f87021ae36ea';
  static final _serviceNameKey = 'viam-provisioning';
  static final _availableWiFiNetworksKey = 'networks';
  static final _ssidKey = 'ssid';
  static final _pskKey = 'psk';
  static final _robotPartIDKey = 'id';
  static final _robotPartSecretKey = 'secret';
  static final _appAddressKey = 'app_address';
  static final _statusKey = 'status';
  static final _cryptoKey = 'pub_key';

  BleCentral? _ble;
  bool _isPoweredOn = false;

  final String _serviceUUID;
  final String _availableWiFiNetworksUUID;
  final String _ssidUUID;
  final String _pskUUID;
  final String _robotPartUUID;
  final String _robotPartSecretUUID;
  final String _appAddressUUID;
  final String _statusUUID;
  final String _cryptoUUID;

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
      uuid.v5(_uuidNamespace, _statusKey),
      uuid.v5(_uuidNamespace, _cryptoKey),
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
    this._statusUUID,
    this._cryptoUUID,
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
      return _convertNetworkListBytes(networkListBytes);
    }
    return [];
  }

  Future<({bool isConfigured, bool isConnected})> readStatus(ConnectedBlePeripheral peripheral) async {
    final bleService = peripheral.services.firstWhere((service) => service.id == _serviceUUID);

    final statusCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _statusUUID);
    final buffer = await statusCharacteristic.read();
    final status = buffer?[0];
    if (status == null) {
      throw Exception('Unable to read status byte');
    }

    bool isConfigured = false;
    bool isConnected = false;
    switch (status) {
      case 0:
        break;
      case 1:
        isConfigured = true;
      case 2:
        isConfigured = false;
      case 3:
        isConfigured = false;
        isConnected = true;
      default:
        throw Exception('Invalid status');
    }
    return (isConfigured: isConfigured, isConnected: isConnected);
  }

  Future<void> writeNetworkConfig({
    required ConnectedBlePeripheral peripheral,
    required String ssid,
    required String pw,
  }) async {
    final bleService = peripheral.services.firstWhere((service) => service.id == _serviceUUID);

    final cryptoCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _cryptoUUID);
    final publicKeyBytes = await cryptoCharacteristic.read();
    if (publicKeyBytes == null) {
      throw Exception('Unable to read public key');
    }
    final publicKey = _publicKey(publicKeyBytes);
    final encoder = _encoder(publicKey);

    final encryptedSSID = encoder.process(utf8.encode(ssid));
    final ssidCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _ssidUUID);
    await ssidCharacteristic.write(encryptedSSID);

    final encryptedPW = encoder.process(utf8.encode(pw));
    final pskCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _pskUUID);
    await pskCharacteristic.write(encryptedPW);
  }

  Future<void> writeRobotPartConfig({
    required ConnectedBlePeripheral peripheral,
    required String partId,
    required String secret,
    String appAddress = 'https://app.viam.com:443',
  }) async {
    final bleService = peripheral.services.firstWhere((service) => service.id == _serviceUUID);

    final cryptoCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _cryptoUUID);
    final publicKeyBytes = await cryptoCharacteristic.read();
    if (publicKeyBytes == null) {
      throw Exception('Unable to read public key');
    }
    final publicKey = _publicKey(publicKeyBytes);
    final encoder = _encoder(publicKey);

    final encodedPartId = encoder.process(utf8.encode(partId));
    final partIdCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _robotPartUUID);
    await partIdCharacteristic.write(encodedPartId);

    final encodedSecret = encoder.process(utf8.encode(secret));
    final partSecretCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _robotPartSecretUUID);
    await partSecretCharacteristic.write(encodedSecret);

    final encodedAppAddress = encoder.process(utf8.encode(appAddress));
    final appAddressCharacteristic = bleService.characteristics.firstWhere((char) => char.id == _appAddressUUID);
    await appAddressCharacteristic.write(encodedAppAddress);
  }

  // Helper functions

  static List<WifiNetwork> _convertNetworkListBytes(Uint8List bytes) {
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

  RSAPublicKey _publicKey(Uint8List keyBytes) {
    final parser = ASN1Parser(keyBytes);
    final topLevelSeq = parser.nextObject() as ASN1Sequence;

    final pubKeyBitString = topLevelSeq.elements?[1] as ASN1BitString;

    final pkParser = ASN1Parser(pubKeyBitString.stringValues as Uint8List);
    final pkSeq = pkParser.nextObject() as ASN1Sequence;
    final modulus = (pkSeq.elements?[0] as ASN1Integer).integer;
    final exponent = (pkSeq.elements?[1] as ASN1Integer).integer;

    if (modulus == null || exponent == null) {
      throw Exception('Unable to parse public key');
    }
    return RSAPublicKey(modulus, exponent);
  }

  OAEPEncoding _encoder(RSAPublicKey publicKey) {
    return OAEPEncoding.withSHA256(RSAEngine())..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  }
}
