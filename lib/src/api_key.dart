part of '../viam_bluetooth_provisioning.dart';

class APIKey {
  final String id;
  final String key;

  APIKey({required this.id, required this.key});

  String toJson() {
    return jsonEncode({'id': id, 'key': key});
  }
}
