import 'package:flutter/material.dart';
import 'package:viam_flutter_provisioning/viam_bluetooth_provisioning.dart';

import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Provisioning',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(provisioning: ViamBluetoothProvisioning()),
    );
  }
}
