part of '../viam_bluetooth_provisioning.dart';

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
