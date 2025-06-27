part of '../viam_bluetooth_provisioning.dart';

// Reading

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

  Future<String> readAgentVersion() async {
    List<BluetoothService> services = await discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID);

    final agentVersionCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.agentVersionUUID,
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

  Future<void> exitProvisioning() async {
    List<BluetoothService> services = await discoverServices();

    final bleService = services.firstWhere((service) => service.uuid.str == ViamBluetoothUUIDs.serviceUUID);

    final cryptoCharacteristic = bleService.characteristics.firstWhere((char) => char.uuid.str == ViamBluetoothUUIDs.cryptoUUID);
    final publicKeyBytes = await cryptoCharacteristic.read();
    final publicKey = _publicKey(Uint8List.fromList(publicKeyBytes));
    final encoder = _encoder(publicKey);

    final exitProvisioningCharacteristic = bleService.characteristics.firstWhere(
      (char) => char.uuid.str == ViamBluetoothUUIDs.exitProvisioningUUID,
    );
    // "1" is arbitrary
    await exitProvisioningCharacteristic.write(encoder.process(utf8.encode("1")));
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
