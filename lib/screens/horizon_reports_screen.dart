import 'package:flutter/material.dart';

class HorizonReportsScreen extends StatelessWidget {
  const HorizonReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horizon Reports')),
      body: const Center(
        child: Text(
          'Horizon Reports',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
