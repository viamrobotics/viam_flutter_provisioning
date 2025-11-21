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
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final Set<String> _deviceIds = {};
  List<ScanResult> _uniqueDevices = [];
  bool _isConnecting = false;
  final ViamBluetoothProvisioning _viamBluetoothProvisioning = ViamBluetoothProvisioning();

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
    _viamBluetoothProvisioning.initialize(poweredOn: (poweredOn) {
      if (poweredOn) {
        _startScan();
      }
    });
  }

  void _startScan() async {
    final stream = await _viamBluetoothProvisioning.scanForPeripherals();
    _scanSubscription = stream.listen((device) {
      setState(() {
        for (final result in device) {
          if (!_deviceIds.contains(result.device.remoteId.str)) {
            _deviceIds.add(result.device.remoteId.str);
            _uniqueDevices.add(result);
          }
        }
        _uniqueDevices = _uniqueDevices;
      });
    });
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  void _connect(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
    });
    try {
      await device.connect();
      _pushToConnectedScreen(device);
    } catch (e) {
      debugPrint('Error connecting to device: ${e.toString()}');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _pushToConnectedScreen(BluetoothDevice device) {
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProvisionPeripheralScreen(device: device),
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
                  title: Text(
                    _uniqueDevices[index].device.platformName.isNotEmpty ? _uniqueDevices[index].device.platformName : 'Untitled',
                  ),
                  subtitle: Text(_uniqueDevices[index].device.remoteId.str),
                  onTap: () => _connect(_uniqueDevices[index].device),
                );
              },
            ),
    );
  }
}
