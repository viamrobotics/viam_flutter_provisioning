import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:viam_flutter_provisioning/viam_bluetooth_provisioning.dart';

import 'provision_peripheral_screen.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreen();
}

class _ScanningScreen extends State<ScanningScreen> {
  final ViamBluetoothProvisioning _provisioning = ViamBluetoothProvisioning();
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final Set<String> _deviceIds = {};
  List<ScanResult> _uniqueDevices = [];
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

  void _startScan() async {
    final stream = await _provisioning.scanForPeripherals();
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
      await _provisioning.connectToPeripheral(device);
      _pushToConnectedScreen(device);
    } catch (e) {
      print(e);
    }
    setState(() {
      _isConnecting = false;
    });
  }

  void _pushToConnectedScreen(BluetoothDevice connectedPeripheral) {
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProvisionPeripheralScreen(
            connectedBlePeripheral: connectedPeripheral,
            provisioning: _provisioning,
          ),
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
                    _uniqueDevices[index].advertisementData.advName.isNotEmpty
                        ? _uniqueDevices[index].advertisementData.advName
                        : 'Untitled',
                  ),
                  subtitle: Text(_uniqueDevices[index].device.remoteId.str),
                  onTap: () => _connect(_uniqueDevices[index].device),
                );
              },
            ),
    );
  }
}
