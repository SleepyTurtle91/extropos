import 'package:flutter/material.dart';

/// ResponsiveLayout provides simple breakpoints and helpers to adapt UIs
/// across narrow (phone), medium (tablet) and wide (desktop) screens.
///
/// Usage:
/// ResponsiveLayout(
///   builder: (context, constraints, info) => ...
/// )
class ResponsiveInfo {
  final double width;
  final double height;
  final bool isPortrait;
  final int columns;

  ResponsiveInfo({
    required this.width,
    required this.height,
    required this.isPortrait,
    required this.columns,
  });
}

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext, BoxConstraints, ResponsiveInfo) builder;

  const ResponsiveLayout({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final isPortrait =
            MediaQuery.of(context).orientation == Orientation.portrait;

        // Enhanced breakpoint logic for better responsiveness across all screen sizes
        int columns;
        if (width < 480) {
          columns = 1; // Small phones
        } else if (width < 600) {
          columns = 2; // Regular phones
        } else if (width < 900) {
          columns = 3; // Tablets/small laptops
        } else if (width < 1200) {
          columns = 4; // Laptops
        } else if (width < 1600) {
          columns = 5; // Large desktops
        } else if (width < 2560) {
          columns = 6; // Ultra-wide displays
        } else if (width < 3840) {
          columns = 7; // 4K displays
        } else {
          columns = 8; // Ultra-wide 4K+ displays
        }

        final info = ResponsiveInfo(
          width: width,
          height: height,
          isPortrait: isPortrait,
          columns: columns,
        );

        return builder(context, constraints, info);
      },
    );
  }
}
