import 'package:flutter/material.dart';

class HorizonPulseDashboardScreen extends StatelessWidget {
  const HorizonPulseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horizon Dashboard')),
      body: const Center(
        child: Text(
          'Horizon Pulse Dashboard',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
