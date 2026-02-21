import 'package:flutter/material.dart';

/// ResponsiveRow switches between a [Row] (for wide layouts) and a [Column]
/// (for narrow screens). It accepts separate children lists for row and column
/// modes so widgets can be composed differently for each case.
class ResponsiveRow extends StatelessWidget {
  final List<Widget> rowChildren;
  final List<Widget>? columnChildren;
  final double breakpoint;
  final double spacing;
  final double runSpacing;

  const ResponsiveRow({
    super.key,
    required this.rowChildren,
    this.columnChildren,
    this.breakpoint = 700,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: rowChildren,
          );
        }

        final column = columnChildren ?? rowChildren;
        // Use a Column with spacing between items
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: column
              .map(
                (w) => Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: w,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
