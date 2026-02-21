import 'package:flutter/material.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guide'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _GuideSection(
            title: 'Getting Started',
            content:
                'Welcome to ExtroPOS! To begin, make sure you have set up your business information in Settings > Business Setup. '
                'You can then add products in Products & Inventory > Products Management.',
          ),
          _GuideSection(
            title: 'Business Modes',
            content:
                'ExtroPOS supports three modes:\n\n'
                '1. Retail Mode: For quick sales with a cart and checkout.\n'
                '2. Cafe Mode: Similar to Retail but includes order numbering for takeaway/counter service.\n'
                '3. Restaurant Mode: Includes table management for dine-in service.',
          ),
          _GuideSection(
            title: 'Processing Sales',
            content:
                '1. Select items from the product grid to add them to the cart.\n'
                '2. Tap "Charge" to proceed to payment.\n'
                '3. Select a payment method and enter the amount.\n'
                '4. Complete the transaction to print a receipt.',
          ),
          _GuideSection(
            title: 'Shift Management',
            content:
                'Use the clock icon in the top bar to manage shifts. '
                'You must start a shift to process orders. '
                'End your shift to reconcile cash and view a shift report.',
          ),
          _GuideSection(
            title: 'Business Sessions',
            content:
                'A Business Session represents a financial day. '
                'Open a session at the start of the day with an opening float. '
                'Close the session at the end of the day to generate a closing report.',
          ),
          _GuideSection(
            title: 'Reports',
            content:
                'View detailed sales reports in Reports & Analytics. '
                'You can view sales by product, category, payment method, and more. '
                'Reports can be exported to PDF or printed.',
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String title;
  final String content;

  const _GuideSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(content, style: const TextStyle(height: 1.5)),
          ),
        ],
      ),
    );
  }
}
