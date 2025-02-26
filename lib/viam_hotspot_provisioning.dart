import 'dart:async';

import 'package:viam_sdk/viam_sdk.dart';

class ViamHotspotProvisioning {
  final ProvisioningClient provisioningClient;

  ViamHotspotProvisioning({required this.provisioningClient});

  /// Gets a list of networks from viam-agent that are visible to the smart machine. (this only works for hotspot currently)
  Future<List<NetworkInfo>> getNetworkList() async {
    final response = await provisioningClient.getNetworkList();
    return response.toList()..sort((b, a) => a.signal.compareTo(b.signal));
  }

  /// setNetworkCredentials and setSmartMachineCredentials need to be called as close to eachother as possible,
  /// there is a 10 second window on the viam-agent side once one has been recieved before it turns off the
  /// hotspot*** (what about bluetooth?) and attempts to connect.
  ///
  /// Sends the network credentials for Wi-Fi to the smart machine to add
  /// to its network manager and attempt to connect. If the network has no passkey,
  /// send an empty string.
  Future<void> setNetworkCredentials(String ssid, String psk) async {
    await provisioningClient.setNetworkCredentials(ssid: ssid, psk: psk);
  }

  /// Sends the Viam Robot Secret & ID to the smart machine to store in its viam.json
  Future<void> setSmartMachineCredentials(String id, String secret) async {
    // TODO: need a mainPart for this id and secret! we create a new robot when we do this currently
    await provisioningClient.setSmartMachineCredentials(id: id, secret: secret);
  }

  // TODO: could sort of modify to return when it's online only
  Future<GetSmartMachineStatusResponse> getSmartMachineStatus() async {
    return await provisioningClient.getSmartMachineStatus();
  }
}
