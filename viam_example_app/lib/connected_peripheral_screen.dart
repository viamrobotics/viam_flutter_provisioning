import 'dart:async';

import 'package:flutter/material.dart';
import 'package:viam_flutter_provisioning/viam_bluetooth_provisioning.dart';
import 'package:blev/ble_central.dart'; // ignore: depend_on_referenced_packages

class ConnectedPeripheralScreen extends StatefulWidget {
  const ConnectedPeripheralScreen({super.key, required this.provisioning, required this.connectedBlePeripheral});

  final ViamBluetoothProvisioning provisioning; // TODO: needed..?
  final ConnectedBlePeripheral connectedBlePeripheral;

  @override
  State<ConnectedPeripheralScreen> createState() => _ConnectedPeripheralScreen();
}

class _ConnectedPeripheralScreen extends State<ConnectedPeripheralScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _readCharacteristic(BleCharacteristic characteristic) async {
    // TODO: loading
    try {
      final readBytes = await characteristic.read();
      print(readBytes); // convert 2 string
    } catch (e) {
      print(e);
    }
    // TODO: show in UI? snackbar/toast
  }

  void _writeCharacteristic(BleCharacteristic characteristic) async {
    // ...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connectedBlePeripheral.id),
      ),
      body: ListView.builder(
        itemCount: widget.connectedBlePeripheral.services.length,
        itemBuilder: (context, serviceIndex) {
          final service = widget.connectedBlePeripheral.services[serviceIndex];
          return ExpansionTile(
            leading: const Icon(Icons.bluetooth_connected, color: Colors.blue),
            title: Text('Service: ${service.id}'),
            children: service.characteristics.map((characteristic) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ListTile(
                  title: Text('Characteristic: ${characteristic.id}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => _readCharacteristic(characteristic),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
