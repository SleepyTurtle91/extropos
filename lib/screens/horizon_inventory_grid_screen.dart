import 'package:flutter/material.dart';

class HorizonInventoryGridScreen extends StatelessWidget {
  const HorizonInventoryGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horizon Inventory')),
      body: const Center(
        child: Text(
          'Horizon Inventory Grid',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
