import 'package:flutter/material.dart';
import 'scanning_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Provisioning'),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ScanningScreen())),
          child: const Text('Start Scanning'),
        ),
      ),
    );
  }
}
