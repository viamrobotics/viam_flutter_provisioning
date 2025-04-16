import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';

import 'wifi_network.dart';

// MV
class ViamBluetoothUUIDs {
  static String serviceUUID = _uuid.v5(_namespace, _serviceNameKey);
  static String availableWiFiNetworksUUID = _uuid.v5(_namespace, _availableWiFiNetworksKey);
  static String ssidUUID = _uuid.v5(_namespace, _ssidKey);
  static String pskUUID = _uuid.v5(_namespace, _pskKey);
  static String robotPartUUID = _uuid.v5(_namespace, _robotPartIDKey);
  static String robotPartSecretUUID = _uuid.v5(_namespace, _robotPartSecretKey);
  static String appAddressUUID = _uuid.v5(_namespace, _appAddressKey);
  static String statusUUID = _uuid.v5(_namespace, _statusKey);
  static String cryptoUUID = _uuid.v5(_namespace, _cryptoKey);
  static String errorsUUID = _uuid.v5(_namespace, _errorsKey);
  static String fragmentUUID = _uuid.v5(_namespace, _fragmentKey);
  static String manufacturerUUID = _uuid.v5(_namespace, _manufacturerKey);
  static String modelUUID = _uuid.v5(_namespace, _modelKey);

  static const String _namespace = '74a942f4-0f45-43f4-88ca-f87021ae36ea';
  static const String _serviceNameKey = 'viam-provisioning';
  static const String _availableWiFiNetworksKey = 'networks';
  static const String _ssidKey = 'ssid';
  static const String _pskKey = 'psk';
  static const String _robotPartIDKey = 'id';
  static const String _robotPartSecretKey = 'secret';
  static const String _appAddressKey = 'app_address';
  static const String _statusKey = 'status';
  static const String _cryptoKey = 'pub_key';
  static const String _errorsKey = 'errors';
  static const String _fragmentKey = 'fragment_id';
  static const String _manufacturerKey = 'manufacturer';
  static const String _modelKey = 'model';
  static final _uuid = Uuid();
}

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

// MV - ViamReading+BluetoothDevice.dart
extension ViamReading on BluetoothDevice {
  Future<List<WifiNetwork>> readNetworkList() async {
    List<BluetoothService> services = await discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID);

    final networkListCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.availableWiFiNetworksUUID,
    );
    final networkListBytes = await networkListCharacteristic.read();
    return ViamBluetoothProvisioning.convertNetworkListBytes(Uint8List.fromList(networkListBytes));
  }

  Future<({bool isConfigured, bool isConnected})> readStatus() async {
    List<BluetoothService> services = await discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID);

    final statusCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.statusUUID);
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
        isConnected = true;
      case 3:
        isConfigured = true;
        isConnected = true;
      default:
        throw Exception('Invalid status');
    }
    return (isConfigured: isConfigured, isConnected: isConnected);
  }

  Future<String> readErrors() async {
    List<BluetoothService> services = await discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID);

    final errorsCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.errorsUUID);
    final errorsBytes = await errorsCharacteristic.read();
    return utf8.decode(errorsBytes);
  }

  Future<String> readFragmentId() async {
    List<BluetoothService> services = await discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID);

    final fragmentIdCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.fragmentUUID);
    final fragmentIdBytes = await fragmentIdCharacteristic.read();
    return utf8.decode(fragmentIdBytes);
  }

  Future<String> readManufacturer() async {
    List<BluetoothService> services = await discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID);

    final manufacturerCharacteristic =
        bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.manufacturerUUID);
    final manufacturerBytes = await manufacturerCharacteristic.read();
    return utf8.decode(manufacturerBytes);
  }

  Future<String> readModel() async {
    List<BluetoothService> services = await discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID);

    final modelCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.modelUUID);
    final modelBytes = await modelCharacteristic.read();
    return utf8.decode(modelBytes);
  }
}

// MV - ViamWriting+BluetoothDevice.dart
extension ViamWriting on BluetoothDevice {
  Future<void> writeNetworkConfig({
    required String ssid,
    String? pw,
  }) async {
    List<BluetoothService> services = await discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID);

    final cryptoCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.cryptoUUID);
    final publicKeyBytes = await cryptoCharacteristic.read();
    final publicKey = _publicKey(Uint8List.fromList(publicKeyBytes));
    final encoder = _encoder(publicKey);

    final encodedSSID = encoder.process(utf8.encode(ssid));
    final ssidCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.ssidUUID);
    await ssidCharacteristic.write(encodedSSID);

    final encodedPW = encoder.process(utf8.encode(pw ?? 'NONE'));
    final pskCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.pskUUID);
    await pskCharacteristic.write(encodedPW);
  }

  Future<void> writeRobotPartConfig({
    required String partId,
    required String secret,
    String appAddress = 'https://app.viam.com:443',
  }) async {
    List<BluetoothService> services = await discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID);

    final cryptoCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.cryptoUUID);
    final publicKeyBytes = await cryptoCharacteristic.read();
    final publicKey = _publicKey(Uint8List.fromList(publicKeyBytes));
    final encoder = _encoder(publicKey);

    final encodedPartId = encoder.process(utf8.encode(partId));
    final partIdCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.robotPartUUID);
    await partIdCharacteristic.write(encodedPartId);

    final encodedSecret = encoder.process(utf8.encode(secret));
    final partSecretCharacteristic =
        bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.robotPartSecretUUID);
    await partSecretCharacteristic.write(encodedSecret);

    final encodedAppAddress = encoder.process(utf8.encode(appAddress));
    final appAddressCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.appAddressUUID);
    await appAddressCharacteristic.write(encodedAppAddress);
  }

  static RSAPublicKey _publicKey(Uint8List keyBytes) {
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

  static OAEPEncoding _encoder(RSAPublicKey publicKey) {
    return OAEPEncoding.withSHA256(RSAEngine())..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  }
}
