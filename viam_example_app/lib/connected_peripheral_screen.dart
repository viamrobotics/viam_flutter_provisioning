import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:viam_flutter_provisioning/viam_bluetooth_provisioning.dart';

class ConnectedPeripheralScreen extends StatefulWidget {
  const ConnectedPeripheralScreen({super.key, required this.connectedBlePeripheral});

  final ConnectedBlePeripheral connectedBlePeripheral;

  @override
  State<ConnectedPeripheralScreen> createState() => _ConnectedPeripheralScreen();
}

class _ConnectedPeripheralScreen extends State<ConnectedPeripheralScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _readCharacteristic(BleCharacteristic characteristic) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final readBytes = await characteristic.read();
      final readString = utf8.decode(readBytes ?? []);
      _showSnackBar(readString);
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _writeCharacteristic(BleCharacteristic characteristic, String value) async {
    setState(() {
      _isLoading = true;
    });
    final writeBytes = utf8.encode(value);
    try {
      await characteristic.write(writeBytes);
      _showSnackBar('Wrote $value');
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showWriteDialog(BleCharacteristic characteristic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Write to: ${characteristic.id}'),
        content: TextField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: 'Enter value',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _writeCharacteristic(characteristic, _textController.text),
            child: const Text('Write'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connectedBlePeripheral.id),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
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
                            TextButton(
                              onPressed: () => _readCharacteristic(characteristic),
                              child: const Text('read'),
                            ),
                            TextButton(
                              onPressed: () => _showWriteDialog(characteristic),
                              child: const Text('write'),
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
