import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:viam_flutter_provisioning/viam_bluetooth_provisioning.dart';

void main() {
  test('Test network list decoding', () {
    final network1 = [
      0xB2, // Meta byte (50 | 10000000 = 178 = 0xb2)
      ...utf8.encode("foobar"),
      0x0,
    ];

    final network2 = [
      75, // Meta byte (75, no security bit)
      ...utf8.encode("TestWifi"),
      0x0,
    ];

    final bytes = Uint8List.fromList([
      ...network1,
      ...network2,
    ]);

    final networks = ViamBluetoothProvisioning.convertNetworkListBytes(bytes);
    expect(networks.length, 2);
    expect(networks[0].ssid, 'foobar');
    expect(networks[0].signalStrength, 50);
    expect(networks[0].isSecure, true);

    expect(networks[1].ssid, 'TestWifi');
    expect(networks[1].signalStrength, 75);
    expect(networks[1].isSecure, false);
  });
}
