import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
  static final _errorsKey = 'errors';
  static final _fragmentKey = 'fragment_id';

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
  final String _errorsUUID;
  final String _fragmentUUID;

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
      uuid.v5(_uuidNamespace, _errorsKey),
      uuid.v5(_uuidNamespace, _fragmentKey),
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
    this._errorsUUID,
    this._fragmentUUID,
  );

  Future<void> initialize({Function(bool)? poweredOn}) async {
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false);
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        _isPoweredOn = true;
      } else {
        _isPoweredOn = false;
      }
      poweredOn?.call(_isPoweredOn);
    });
  }

  /// Scans for peripherals with the Viam bluetooth provisioning service UUID
  Future<Stream<List<ScanResult>>> scanForPeripherals() async {
    await FlutterBluePlus.startScan(withServices: [Guid(_serviceUUID)]);
    return FlutterBluePlus.onScanResults;
  }

  Future<void> connectToPeripheral(BluetoothDevice peripheral) async {
    await peripheral.connect();
  }

  Future<List<WifiNetwork>> readNetworkList(BluetoothDevice peripheral) async {
    List<BluetoothService> services = await peripheral.discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == _serviceUUID);

    final networkListCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == _availableWiFiNetworksUUID);
    final networkListBytes = await networkListCharacteristic.read();
    return convertNetworkListBytes(Uint8List.fromList(networkListBytes));
  }

  Future<({bool isConfigured, bool isConnected})> readStatus(BluetoothDevice peripheral) async {
    List<BluetoothService> services = await peripheral.discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == _serviceUUID);

    final statusCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == _statusUUID);
    final buffer = await statusCharacteristic.read();
    final status = buffer[0];

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

  Future<String> readErrors(BluetoothDevice peripheral) async {
    List<BluetoothService> services = await peripheral.discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == _serviceUUID);

    final errorsCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == _errorsUUID);
    final errorsBytes = await errorsCharacteristic.read();
    return utf8.decode(errorsBytes);
  }

  Future<String> readFragmentId(BluetoothDevice peripheral) async {
    List<BluetoothService> services = await peripheral.discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == _serviceUUID);

    final fragmentCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == _fragmentUUID);
    final fragmentBytes = await fragmentCharacteristic.read();
    return utf8.decode(fragmentBytes);
  }

  Future<void> writeNetworkConfig({
    required BluetoothDevice peripheral,
    required String ssid,
    String? pw,
  }) async {
    List<BluetoothService> services = await peripheral.discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == _serviceUUID);

    final cryptoCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == _cryptoUUID);
    final publicKeyBytes = await cryptoCharacteristic.read();
    final publicKey = _publicKey(Uint8List.fromList(publicKeyBytes));
    final encoder = _encoder(publicKey);

    final encodedSSID = encoder.process(utf8.encode(ssid));
    final ssidCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == _ssidUUID);
    await ssidCharacteristic.write(encodedSSID);

    final encodedPW = encoder.process(utf8.encode(pw ?? 'NONE'));
    final pskCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == _pskUUID);
    await pskCharacteristic.write(encodedPW);
  }

  Future<void> writeRobotPartConfig({
    required BluetoothDevice peripheral,
    required String partId,
    required String secret,
    String appAddress = 'https://app.viam.com:443',
  }) async {
    List<BluetoothService> services = await peripheral.discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == _serviceUUID);

    final cryptoCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == _cryptoUUID);
    final publicKeyBytes = await cryptoCharacteristic.read();
    final publicKey = _publicKey(Uint8List.fromList(publicKeyBytes));
    final encoder = _encoder(publicKey);

    final encodedPartId = encoder.process(utf8.encode(partId));
    final partIdCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == _robotPartUUID);
    await partIdCharacteristic.write(encodedPartId);

    final encodedSecret = encoder.process(utf8.encode(secret));
    final partSecretCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == _robotPartSecretUUID);
    await partSecretCharacteristic.write(encodedSecret);

    final encodedAppAddress = encoder.process(utf8.encode(appAddress));
    final appAddressCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == _appAddressUUID);
    await appAddressCharacteristic.write(encodedAppAddress);
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
