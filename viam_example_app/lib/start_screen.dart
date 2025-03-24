import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

import 'package:flutter/material.dart';
import 'scanning_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  void _requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();
      if (scanStatus == PermissionStatus.granted && connectStatus == PermissionStatus.granted) {
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ScanningScreen()));
        }
      }
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ScanningScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Provisioning'),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () => _requestPermissions(context),
          child: const Text('Start Scanning'),
        ),
      ),
    );
  }
}
