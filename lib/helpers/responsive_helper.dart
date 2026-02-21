import 'package:flutter/material.dart';

/// Helper class for responsive design patterns used throughout the POS app
class ResponsiveHelper {
  /// Get adaptive cross axis count for grids based on screen width
  /// Breakpoints: <600: 1, 600-900: 2, 900-1200: 3, >1200: 4
  static int getAdaptiveCrossAxisCount(BuildContext context, {
    int minColumns = 1,
    int maxColumns = 4,
  }) {
    final width = MediaQuery.of(context).size.width;

    int columns;
    if (width < 600) {
      columns = 1;
    } else if (width < 900) {
      columns = 2;
    } else if (width < 1200) {
      columns = 3;
    } else {
      columns = 4;
    }

    return columns.clamp(minColumns, maxColumns);
  }

  /// Get adaptive cross axis count using LayoutBuilder constraints
  static int getAdaptiveCrossAxisCountFromConstraints(BoxConstraints constraints, {
    int minColumns = 1,
    int maxColumns = 4,
  }) {
    final width = constraints.maxWidth;

    int columns;
    if (width < 600) {
      columns = 1;
    } else if (width < 900) {
      columns = 2;
    } else if (width < 1200) {
      columns = 3;
    } else {
      columns = 4;
    }

    return columns.clamp(minColumns, maxColumns);
  }

  /// Check if layout should be compact based on width
  static bool isCompactLayout(BuildContext context, {double threshold = 600}) {
    return MediaQuery.of(context).size.width < threshold;
  }

  /// Check if layout should be compact using constraints
  static bool isCompactLayoutFromConstraints(BoxConstraints constraints, {double threshold = 600}) {
    return constraints.maxWidth < threshold;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return const EdgeInsets.all(8);
    } else if (width < 900) {
      return const EdgeInsets.all(12);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  /// Get responsive text size multiplier
  static double getTextScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return 0.9; // Smaller text on mobile
    } else if (width < 900) {
      return 1.0; // Normal text on tablet
    } else {
      return 1.1; // Slightly larger text on desktop
    }
  }

  /// Build responsive grid view with automatic column calculation
  static GridView buildResponsiveGrid({
    required BuildContext context,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 8.0,
    double mainAxisSpacing = 8.0,
    int minColumns = 1,
    int maxColumns = 4,
  }) {
    final crossAxisCount = getAdaptiveCrossAxisCount(
      context,
      minColumns: minColumns,
      maxColumns: maxColumns,
    );

    return GridView.builder(
      padding: getResponsivePadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  /// Build responsive grid view using LayoutBuilder
  static LayoutBuilder buildResponsiveGridWithLayoutBuilder({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 8.0,
    double mainAxisSpacing = 8.0,
    int minColumns = 1,
    int maxColumns = 4,
    EdgeInsets? padding,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = getAdaptiveCrossAxisCountFromConstraints(
          constraints,
          minColumns: minColumns,
          maxColumns: maxColumns,
        );

        return GridView.builder(
          padding: padding ?? getResponsivePadding(context),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }

  /// Build responsive row/column layout that switches based on screen size
  static Widget buildResponsiveRowOrColumn({
    required BuildContext context,
    required List<Widget> children,
    double threshold = 800,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width < threshold) {
      // Use column for narrow screens
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    } else {
      // Use row for wide screens
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }
  }

  /// Build responsive card grid that prevents overflow
  static Widget buildResponsiveCardGrid({
    required BuildContext context,
    required List<Widget> cards,
    int minColumns = 1,
    int maxColumns = 4,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = getAdaptiveCrossAxisCountFromConstraints(
          constraints,
          minColumns: minColumns,
          maxColumns: maxColumns,
        );

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: getResponsivePadding(context),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: cards,
        );
      },
    );
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final scale = getTextScaleFactor(context);
    return baseSize * scale;
  }

  /// Build responsive dialog that prevents overflow
  static Widget buildResponsiveDialog({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    double maxWidth = 600,
    double maxHeightRatio = 0.8,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * maxHeightRatio;

    return AlertDialog(
      title: title,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: SingleChildScrollView(
          child: content,
        ),
      ),
      actions: actions,
    );
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    final scale = getTextScaleFactor(context);
    return baseSize * scale;
  }

  /// Check if we should show detailed view (more info on larger screens)
  static bool shouldShowDetailedView(BuildContext context, {double threshold = 900}) {
    return MediaQuery.of(context).size.width >= threshold;
  }
}