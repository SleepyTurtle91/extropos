import 'package:flutter/material.dart';

/// Small wrapper that constrains dialog content to avoid overflow on small screens
class ConstrainedDialog extends StatelessWidget {
  final Widget child;
  final double maxHeightFactor;
  final double maxWidthFactor;

  const ConstrainedDialog({super.key, required this.child, this.maxHeightFactor = 0.75, this.maxWidthFactor = 0.95});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: mq.height * maxHeightFactor,
        maxWidth: mq.width * maxWidthFactor,
      ),
      child: SingleChildScrollView(
        child: child,
      ),
    );
  }
}
