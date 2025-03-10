import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:viam_flutter_provisioning/viam_bluetooth_provisioning.dart';

class ProvisionPeripheralScreen extends StatefulWidget {
  const ProvisionPeripheralScreen({super.key, required this.connectedBlePeripheral});

  final ConnectedBlePeripheral connectedBlePeripheral;

  @override
  State<ProvisionPeripheralScreen> createState() => _ProvisionPeripheralScreen();
}

class _ProvisionPeripheralScreen extends State<ProvisionPeripheralScreen> {
  final TextEditingController _ssidTextController = TextEditingController();
  final TextEditingController _passkeyTextController = TextEditingController();
  List<String> _networkList = ['test1', 'test2', 'test3'];
  bool _isLoadingNetworkList = false;

  @override
  void initState() {
    super.initState();
    _readNetworkList();
  }

  @override
  void dispose() {
    _ssidTextController.dispose();
    _passkeyTextController.dispose();
    super.dispose();
  }

  void _readNetworkList() async {
    setState(() {
      _isLoadingNetworkList = true;
    });
    try {
      final networkList = await ViamBluetoothProvisioning.readNetworkList(widget.connectedBlePeripheral);
      setState(() {
        _networkList = networkList;
        _isLoadingNetworkList = false;
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoadingNetworkList = false;
      });
    }
  }

  void _writeNetworkConfig() async {
    final ssid = _ssidTextController.text;
    final passkey = _passkeyTextController.text;
    await ViamBluetoothProvisioning.writeNetworkConfig(widget.connectedBlePeripheral, ssid, passkey);
    _showSnackBar('Wrote network config');
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ssidTextController,
              decoration: const InputDecoration(labelText: 'SSID'),
            ),
            TextField(
              controller: _passkeyTextController,
              decoration: const InputDecoration(labelText: 'Passkey'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _writeNetworkConfig,
              child: const Text('Write Network Config'), // TODO: show loading here
            ),
            const SizedBox(height: 16),
            if (_isLoadingNetworkList)
              const Center(child: CircularProgressIndicator())
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _networkList.length,
                itemBuilder: (context, index) {
                  final network = _networkList[index];
                  return ListTile(
                    leading: const Icon(Icons.wifi, color: Colors.blue),
                    title: Text('Network: $network'),
                    onTap: () => setState(() => _ssidTextController.text = network),
                    selected: _ssidTextController.text == network,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
