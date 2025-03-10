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

  final TextEditingController _partIdTextController = TextEditingController();
  final TextEditingController _secretTextController = TextEditingController();
  final TextEditingController _appAddressTextController = TextEditingController();

  List<String> _networkList = [];

  bool _isLoadingNetworkList = false;
  bool _isWritingNetworkConfig = false;
  bool _isWritingRobotPartConfig = false;

  @override
  void initState() {
    super.initState();
    _readNetworkList();
  }

  @override
  void dispose() {
    _ssidTextController.dispose();
    _passkeyTextController.dispose();
    _partIdTextController.dispose();
    _secretTextController.dispose();
    _appAddressTextController.dispose();
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
      print('Error reading network list: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingNetworkList = false;
      });
    }
  }

  void _writeNetworkConfig() async {
    setState(() {
      _isWritingNetworkConfig = true;
    });
    try {
      final ssid = _ssidTextController.text;
      final passkey = _passkeyTextController.text;
      await ViamBluetoothProvisioning.writeNetworkConfig(widget.connectedBlePeripheral, ssid, passkey);
      _showSnackBar('Wrote network config');
    } catch (e) {
      print('Error writing network config: ${e.toString()}');
    } finally {
      setState(() {
        _isWritingNetworkConfig = false;
      });
    }
  }

  void _writeRobotPartConfig() async {
    setState(() {
      _isWritingRobotPartConfig = true;
    });
    try {
      final partId = _partIdTextController.text;
      final secret = _secretTextController.text;
      final appAddress = _appAddressTextController.text;
      await ViamBluetoothProvisioning.writeRobotPartConfig(widget.connectedBlePeripheral, partId, secret, appAddress);
      _showSnackBar('Wrote robot part config');
    } catch (e) {
      print('Error writing robot part config: ${e.toString()}');
    } finally {
      setState(() {
        _isWritingRobotPartConfig = false;
      });
    }
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
        child: SingleChildScrollView(
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
                child: _isWritingNetworkConfig ? const CircularProgressIndicator.adaptive() : const Text('Write Network Config'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _partIdTextController,
                decoration: const InputDecoration(labelText: 'Part ID'),
              ),
              TextField(
                controller: _secretTextController,
                decoration: const InputDecoration(labelText: 'Secret'),
              ),
              TextField(
                controller: _appAddressTextController,
                decoration: const InputDecoration(labelText: 'App Address'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _writeRobotPartConfig,
                child: _isWritingRobotPartConfig ? const CircularProgressIndicator.adaptive() : const Text('Write Robot Part Config'),
              ),
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
      ),
    );
  }
}
