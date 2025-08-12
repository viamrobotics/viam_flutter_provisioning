part of '../viam_bluetooth_provisioning.dart';

// Reading

extension ViamReading on BluetoothDevice {
  Future<List<WifiNetwork>> readNetworkList() async {
    List<BluetoothService> services = await discoverServices(subscribeToServicesChanged: false);

    final bleService = services.firstWhere(
      (service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID,
      orElse: () => throw Exception('bleService not found'),
    );
    final networkListCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.availableWiFiNetworksUUID,
      orElse: () => throw Exception('networkListCharacteristic not found'),
    );

    final networkListBytes = await networkListCharacteristic.read();
    return ViamBluetoothProvisioning.convertNetworkListBytes(Uint8List.fromList(networkListBytes));
  }

  Future<({bool isConfigured, bool isConnected})> readStatus() async {
    List<BluetoothService> services = await discoverServices(subscribeToServicesChanged: false);

    final bleService = services.firstWhere(
      (service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID,
      orElse: () => throw Exception('bleService not found'),
    );
    final statusCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.statusUUID,
      orElse: () => throw Exception('statusCharacteristic not found'),
    );

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

  /// Errors are returned in a list ordered from oldest to newest.
  Future<List<String>> readErrors() async {
    List<BluetoothService> services = await discoverServices(subscribeToServicesChanged: false);

    final bleService = services.firstWhere(
      (service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID,
      orElse: () => throw Exception('bleService not found'),
    );
    final errorsCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.errorsUUID,
      orElse: () => throw Exception('errorsCharacteristic not found'),
    );

    final errorsBytes = await errorsCharacteristic.read();
    final errorsString = String.fromCharCodes(errorsBytes); // not decoding with utf8 or it stops at first null byte
    // split by null bytes and filter out empty strings
    final errorList = errorsString.split('\x00').where((error) => error.isNotEmpty).toList();
    return errorList;
  }

  Future<String> readFragmentId() async {
    List<BluetoothService> services = await discoverServices(subscribeToServicesChanged: false);

    final bleService = services.firstWhere(
      (service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID,
      orElse: () => throw Exception('bleService not found'),
    );
    final fragmentIdCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.fragmentUUID,
      orElse: () => throw Exception('fragmentIdCharacteristic not found'),
    );

    final fragmentIdBytes = await fragmentIdCharacteristic.read();
    return utf8.decode(fragmentIdBytes);
  }

  Future<String> readManufacturer() async {
    List<BluetoothService> services = await discoverServices(subscribeToServicesChanged: false);

    final bleService = services.firstWhere(
      (service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID,
      orElse: () => throw Exception('bleService not found'),
    );
    final manufacturerCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.manufacturerUUID,
      orElse: () => throw Exception('manufacturerCharacteristic not found'),
    );

    final manufacturerBytes = await manufacturerCharacteristic.read();
    return utf8.decode(manufacturerBytes);
  }

  Future<String> readModel() async {
    List<BluetoothService> services = await discoverServices(subscribeToServicesChanged: false);

    final bleService = services.firstWhere(
      (service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID,
      orElse: () => throw Exception('bleService not found'),
    );
    final modelCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.modelUUID,
      orElse: () => throw Exception('modelCharacteristic not found'),
    );

    final modelBytes = await modelCharacteristic.read();
    return utf8.decode(modelBytes);
  }

  Future<String> readAgentVersion() async {
    List<BluetoothService> services = await discoverServices(subscribeToServicesChanged: false);

    final bleService = services.firstWhere(
      (service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID,
      orElse: () => throw Exception('bleService not found'),
    );
    final agentVersionCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.agentVersionUUID,
      orElse: () => throw Exception('agentVersionCharacteristic not found'),
    );

    final agentVersionBytes = await agentVersionCharacteristic.read();
    return utf8.decode(agentVersionBytes);
  }
}

// Writing

extension ViamWriting on BluetoothDevice {
  Future<void> writeNetworkConfig({
    required String ssid,
    String? pw,
    String psk = 'viamsetup',
  }) async {
    List<BluetoothService> services = await discoverServices(subscribeToServicesChanged: false);

    final bleService = services.firstWhere(
      (service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID,
      orElse: () => throw Exception('bleService not found'),
    );
    final cryptoCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.cryptoUUID,
      orElse: () => throw Exception('cryptoCharacteristic not found'),
    );

    final publicKeyBytes = await cryptoCharacteristic.read();
    final publicKey = _publicKey(Uint8List.fromList(publicKeyBytes));
    final encoder = _encoder(publicKey);

    final encodedSSID = encoder.process(utf8.encode('$psk:$ssid'));
    final ssidCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.ssidUUID,
      orElse: () => throw Exception('ssidCharacteristic not found'),
    );
    await ssidCharacteristic.write(encodedSSID);

    final encodedPW = encoder.process(utf8.encode('$psk:${pw ?? ''}'));
    final pskCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.pskUUID,
      orElse: () => throw Exception('pskCharacteristic not found'),
    );
    await pskCharacteristic.write(encodedPW);
  }

  Future<void> writeRobotPartConfig({
    required String partId,
    required String secret,
    String appAddress = 'https://app.viam.com:443',
    String psk = 'viamsetup',
  }) async {
    List<BluetoothService> services = await discoverServices(subscribeToServicesChanged: false);

    final bleService = services.firstWhere(
      (service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID,
      orElse: () => throw Exception('bleService not found'),
    );
    final cryptoCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.cryptoUUID,
      orElse: () => throw Exception('cryptoCharacteristic not found'),
    );

    final publicKeyBytes = await cryptoCharacteristic.read();
    final publicKey = _publicKey(Uint8List.fromList(publicKeyBytes));
    final encoder = _encoder(publicKey);

    final encodedPartId = encoder.process(utf8.encode('$psk:$partId'));
    final partIdCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.robotPartUUID,
      orElse: () => throw Exception('partIdCharacteristic not found'),
    );
    await partIdCharacteristic.write(encodedPartId);

    final encodedSecret = encoder.process(utf8.encode('$psk:$secret'));
    final partSecretCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.robotPartSecretUUID,
      orElse: () => throw Exception('partSecretCharacteristic not found'),
    );
    await partSecretCharacteristic.write(encodedSecret);

    final encodedAppAddress = encoder.process(utf8.encode('$psk:$appAddress'));
    final appAddressCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.appAddressUUID,
      orElse: () => throw Exception('appAddressCharacteristic not found'),
    );
    await appAddressCharacteristic.write(encodedAppAddress);
  }

  Future<void> exitProvisioning({String psk = 'viamsetup'}) async {
    List<BluetoothService> services = await discoverServices(subscribeToServicesChanged: false);

    final bleService = services.firstWhere(
      (service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID,
      orElse: () => throw Exception('bleService not found'),
    );
    final cryptoCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.cryptoUUID,
      orElse: () => throw Exception('cryptoCharacteristic not found'),
    );

    final publicKeyBytes = await cryptoCharacteristic.read();
    final publicKey = _publicKey(Uint8List.fromList(publicKeyBytes));
    final encoder = _encoder(publicKey);

    final exitProvisioningCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.exitProvisioningUUID,
      orElse: () => throw Exception('exitProvisioningCharacteristic not found'),
    );
    // "1" is arbitrary
    await exitProvisioningCharacteristic.write(encoder.process(utf8.encode("$psk:1")));
  }

  Future<void> unlockPairing({String psk = 'viamsetup'}) async {
    List<BluetoothService> services = await discoverServices(subscribeToServicesChanged: false);

    final bleService = services.firstWhere(
      (service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID,
      orElse: () => throw Exception('bleService not found'),
    );
    final cryptoCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.cryptoUUID,
      orElse: () => throw Exception('cryptoCharacteristic not found'),
    );

    final publicKeyBytes = await cryptoCharacteristic.read();
    final publicKey = _publicKey(Uint8List.fromList(publicKeyBytes));
    final encoder = _encoder(publicKey);

    final unlockPairingCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.unlockPairingUUID,
      orElse: () => throw Exception('unlockPairingCharacteristic not found'),
    );
    // "1" is expected by the device
    await unlockPairingCharacteristic.write(encoder.process(utf8.encode("$psk:1")));
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
