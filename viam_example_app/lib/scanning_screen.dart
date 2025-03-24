import 'dart:async';

import 'package:flutter/material.dart';
import 'package:viam_flutter_provisioning/viam_bluetooth_provisioning.dart';

import 'provision_peripheral_screen.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreen();
}

class _ScanningScreen extends State<ScanningScreen> {
  final ViamBluetoothProvisioning _provisioning = ViamBluetoothProvisioning();
  StreamSubscription<DiscoveredBlePeripheral>? _scanSubscription;
  final Set<String> _deviceIds = {};
  List<DiscoveredBlePeripheral> _uniqueDevices = [];
  bool _isConnecting = false;

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
    await _provisioning.initialize(poweredOn: (poweredOn) {
      if (poweredOn) {
        _startScan();
      }
    });
  }

  void _startScan() {
    _scanSubscription = _provisioning.scanForPeripherals().listen((device) {
      setState(() {
        if (!_deviceIds.contains(device.id)) {
          _deviceIds.add(device.id);
          _uniqueDevices.add(device);
        }
        _uniqueDevices = _uniqueDevices;
      });
    });
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  void _connect(DiscoveredBlePeripheral device) async {
    setState(() {
      _isConnecting = true;
    });
    try {
      final connectedPeripheral = await _provisioning.connectToPeripheral(device);
      _pushToConnectedScreen(connectedPeripheral);
    } catch (e) {
      print(e);
    }
    setState(() {
      _isConnecting = false;
    });
  }

  void _pushToConnectedScreen(ConnectedBlePeripheral connectedPeripheral) {
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProvisionPeripheralScreen(connectedBlePeripheral: connectedPeripheral),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
      ),
      body: _isConnecting
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _uniqueDevices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.bluetooth, color: Colors.blue),
                  title: Text(_uniqueDevices[index].name ?? 'Untitled'),
                  subtitle: Text(_uniqueDevices[index].id),
                  onTap: () => _connect(_uniqueDevices[index]),
                );
              },
            ),
    );
  }
}
