part of '../viam_bluetooth_provisioning.dart';

class WifiNetwork {
  final String ssid;
  final int signalStrength;
  final bool isSecure;

  WifiNetwork({required this.ssid, required this.signalStrength, required this.isSecure});
}
