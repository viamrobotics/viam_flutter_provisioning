
## Viam Flutter Provisioning (Bluetooth)

Package for provisioning machines using Bluetooth and [viam-agent](https://github.com/viamrobotics/agent).

Hotspot provisioning could be added here though that functionality exists in Viam's main [Flutter SDK](https://github.com/viamrobotics/viam-flutter-sdk/blob/main/lib/src/app/provisioning.dart).

This package is built on top of [flutter_blue_plus](https://github.com/chipweinberger/flutter_blue_plus/tree/master). If you're using another library for Bluetooth this could serve as a guide for your own implementation. Feel free to open a PR adding support for another library.

![IMG_2981](https://github.com/user-attachments/assets/1078bf15-d80b-42d9-b617-65997dc46ef7)
![IMG_2982](https://github.com/user-attachments/assets/650986a9-d46e-49a9-905e-83ccfe79dd54)


When running the example app you will need to run on a physical device to discover nearby devices running `agent` with Bluetooth provisioning.

## Installation

`flutter pub add viam_flutter_provisioning`

## Usage

This library does not handle asking for Bluetooth related permissions. Before initializing and scanning you may need to request permissions. On iOS it doesn't seem to be necessary to ask (it happens automatically on iOS when you initialize [CBCentralManager](https://developer.apple.com/documentation/corebluetooth/cbcentralmanager) which is what is used natively).

### Initializing/Scanning

```dart
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

```dart
  await FlutterBluePlus.startScan(withServices: [Guid(ViamBluetoothUUIDs.serviceUUID)]); // bluetooth service id!
```

Once you have a device you can connect by calling `device.connect()`

After connecting, the Viam specific extensions for reading and writing can be called on the connected device.

### Reading

```dart
  final networkList = await widget.device.readNetworkList();

  final status = await widget.device.readStatus();
  final isConfigured = status.isConfigured;
  final isConnected = status.isConnected;

  // there are additional methods for reading errors, manufacturer, model, etc.!
```  

### Writing

```dart
  await device.writeNetworkConfig(
    ssid: 'Network',
    pw: 'password',
  );
await device.writeRobotPartConfig(
  partId: 'id',
  secret: 'secret',
  // apiKey is the preferred but optional authentication method
  apiKey: APIKey(
    id: 'keyID',
    key: 'key'
  ),
);
  await device.exitProvisioning();
```

To provision you need to write the network config and robot config (in any order), then call `exitProvisioning` on the device.

After writing these configurations successfully your device should come online on [app.viam.com](https://app.viam.com/) after a short period!
