import 'package:flutter/material.dart';

class DealerHomeScreen extends StatelessWidget {
  const DealerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dealer Portal')),
      body: const Center(
        child: Text(
          'Dealer portal home is ready.\nUse this entrypoint to manage dealer operations.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
