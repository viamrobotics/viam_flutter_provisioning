import 'dart:async';

import 'package:flutter/material.dart';
import 'package:viam_flutter_provisioning/viam_bluetooth_provisioning.dart';
// ignore: depend_on_referenced_packages
import 'package:blev/ble_central.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.provisioning});

  final ViamBluetoothProvisioning provisioning;

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  StreamSubscription<DiscoveredBlePeripheral>? _scanSubscription;
  final Set<DiscoveredBlePeripheral> _devicesSet = {};
  List<DiscoveredBlePeripheral> _uniqueDevices = [];

  @override
  void initState() {
    super.initState();
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
      });
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
        title: const Text('Bluetooth Provisioning'),
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
