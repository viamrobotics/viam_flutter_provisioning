import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ConnectedPeripheralScreen extends StatefulWidget {
  const ConnectedPeripheralScreen({super.key, required this.connectedBlePeripheral});

  final BluetoothDevice connectedBlePeripheral;

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

  void _readCharacteristic(BluetoothCharacteristic characteristic) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final readBytes = await characteristic.read();
      final readString = utf8.decode(readBytes);
      _showSnackBar(readString);
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _writeCharacteristic(BluetoothCharacteristic characteristic, String value) async {
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

  void _showWriteDialog(BluetoothCharacteristic characteristic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Write to: ${characteristic.uuid.str}'),
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
        title: Text(widget.connectedBlePeripheral.remoteId.str),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: widget.connectedBlePeripheral.servicesList.length,
              itemBuilder: (context, serviceIndex) {
                final service = widget.connectedBlePeripheral.servicesList[serviceIndex];
                return ExpansionTile(
                  leading: const Icon(Icons.bluetooth_connected, color: Colors.blue),
                  title: Text('Service: ${service.uuid.str}'),
                  children: service.characteristics.map((characteristic) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: ListTile(
                        title: Text('Characteristic: ${characteristic.uuid.str}'),
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
