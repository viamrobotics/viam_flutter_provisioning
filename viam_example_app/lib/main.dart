import 'dart:async';

import 'package:flutter/material.dart';
import 'package:viam_flutter_provisioning/viam_bluetooth_provisioning.dart';
// ignore: depend_on_referenced_packages
import 'package:blev/ble_central.dart';

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
      home: MyHomePage(title: 'Bluetooth Provisioning', provisioning: ViamBluetoothProvisioning()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.provisioning});

  final String title;
  final ViamBluetoothProvisioning provisioning;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription<DiscoveredBlePeripheral>? _scanSubscription;
  final Set<DiscoveredBlePeripheral> _devicesSet = {};
  List<DiscoveredBlePeripheral> _uniqueDevices = [];

  @override
  void initState() {
    super.initState();
    // TODO: permissions
    _initialize();
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  void _initialize() async {
    await widget.provisioning.initialize(poweredOn: (poweredOn) {
      if (poweredOn) {
        _startScan();
      }
    });
  }

  void _startScan() {
    _scanSubscription = widget.provisioning.scanForDevices().listen((device) {
      setState(() {
        _devicesSet.add(device);
        _uniqueDevices = _devicesSet.toList(); // TODO: sort by how close device is..?
        print('Devices: ${_uniqueDevices.length}');
      });
    }, onError: (error) {
      print('Error scanning: $error');
    });
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: _uniqueDevices.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.bluetooth, color: Colors.blue),
            title: Text(_uniqueDevices[index].name.isNotEmpty ? _uniqueDevices[index].name : 'Untitled'),
            subtitle: Text(_uniqueDevices[index].id),
            onTap: () {
              // connect on tap
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tapped on item ${_uniqueDevices[index].name.isNotEmpty ? _uniqueDevices[index].name : 'Untitled'}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
