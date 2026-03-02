import 'package:flutter/material.dart';

class CategoryBreakdownWidget extends StatelessWidget {
  final List<BreakdownItem> breakdownItems;

  const CategoryBreakdownWidget({
    required this.breakdownItems,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Breakdown',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          if (breakdownItems.isEmpty)
            const Expanded(child: Center(child: Text('No category data available.')))
          else
            ...breakdownItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${item.percentage.toStringAsFixed(0)}%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: item.percentage / 100,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(item.color),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BreakdownItem {
  final String label;
  final double percentage;
  final String amount;
  final Color color;

  BreakdownItem({
    required this.label,
    required this.percentage,
    required this.amount,
    required this.color,
  });
}
