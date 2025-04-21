
## Viam Flutter Provisioning (Bluetooth)

Package for provisioning machines using Bluetooth and [viam-agent](https://docs.viam.com/manage/fleet/provision/setup/).

Hotspot provisioning could be added here though that functionality exists in Viam's main [Flutter SDK](https://github.com/viamrobotics/viam-flutter-sdk/blob/main/lib/src/app/provisioning.dart).

This package is built on top of [flutter_blue_plus](https://github.com/chipweinberger/flutter_blue_plus/tree/master). If you're using another library for Bluetooth this could serve as a guide for your own implementation. Feel free to open a PR adding support for another library.

[example pic]

When running the example app you will need to run on a physical device to discover nearby devices running `viam-agent` with Bluetooth provisioning.

## Installation

`flutter pub add viam_flutter_provisioning`

## Usage

This library does not handle asking for Bluetooth related permissions. Before initializing and scanning you may need to request permissions. On iOS it doesn't seem to be necessary to ask (it happens automatically on iOS when you initialize [CBCentralManager](https://developer.apple.com/documentation/corebluetooth/cbcentralmanager) which is what is used natively).

### Initializing/Scanning

```
  ...
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final Set<String> _deviceIds = {};
  List<ScanResult> _uniqueDevices = [];
  ...

  void _initialize() async {
    await ViamBluetoothProvisioning.initialize(poweredOn: (poweredOn) {
      if (poweredOn) {
        _startScan(); // good to scan!
      }
    });
  }

  void _startScan() async {
    final stream = await ViamBluetoothProvisioning.scanForPeripherals();
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
```

And if you want to customize your scanning you can easily use the underlying library directly:

```
  await FlutterBluePlus.startScan(withServices: [Guid(ViamBluetoothUUIDs.serviceUUID)]); // bluetooth service id!
```

Once you have a device you can connect by calling `device.connect()`

After connecting, the Viam specific extensions for reading and writing can be called on the connected device.

### Reading

```
  final networkList = await widget.device.readNetworkList();

  final status = await widget.device.readStatus();
  final isConfigured = status.isConfigured;
  final isConnected = status.isConnected;

  // there are additional methods for reading errors, manufacturer, model, etc.!
```  

### Writing

```
  await device.writeNetworkConfig(
    ssid: 'Network',
    pw: 'password',
  );
  await device.writeRobotPartConfig(
    partId: 'id',
    secret: 'secret,
  );
```

To provision you should write the network config and robot part config at the same time (for now). Or as close together as possible.

After writing these configurations successfully your device should come online on app.viam.com after a short period!