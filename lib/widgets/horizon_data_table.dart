import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/design_system/horizon_typography.dart';
import 'package:flutter/material.dart';

/// Horizon Design System - Advanced Data Table
/// Sortable, filterable table component
class HorizonDataTable extends StatefulWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final String? title;
  final bool sortable;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int?>? onSort;

  const HorizonDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.title,
    this.sortable = true,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
  });

  @override
  State<HorizonDataTable> createState() => _HorizonDataTableState();
}

class _HorizonDataTableState extends State<HorizonDataTable> {
  late int? _sortColumnIndex;
  late bool _sortAscending;
  final List<int> _selectedRows = [];

  @override
  void initState() {
    super.initState();
    _sortColumnIndex = widget.sortColumnIndex;
    _sortAscending = widget.sortAscending;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null || _selectedRows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.title != null && _selectedRows.isEmpty)
                    Text(
                      widget.title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: HorizonColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  if (_selectedRows.isNotEmpty)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: HorizonColors.electricIndigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_selectedRows.length} selected',
                            style: const TextStyle(
                              fontSize: 13,
                              color: HorizonColors.electricIndigo,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedRows.clear();
                            });
                          },
                          label: const Text('Deselect'),
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  const Spacer(),
                  if (_selectedRows.isNotEmpty)
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {},
                          label: const Text('Export'),
                          icon: const Icon(Icons.download, size: 16),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {},
                          label: const Text('Delete'),
                          icon: const Icon(Icons.delete, size: 16),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 32,
                horizontalMargin: 0,
                columns: widget.columns
                    .map(
                      (col) => DataColumn(
                        label: GestureDetector(
                          onTap: widget.sortable
                              ? () {
                                  setState(() {
                                    if (_sortColumnIndex == widget.columns.indexOf(col)) {
                                      _sortAscending = !_sortAscending;
                                    } else {
                                      _sortColumnIndex = widget.columns.indexOf(col);
                                      _sortAscending = true;
                                    }
                                  });
                                  widget.onSort?.call(_sortColumnIndex);
                                }
                              : null,
                          child: Row(
                            children: [
                              col.label,
                              if (widget.sortable &&
                                  _sortColumnIndex == widget.columns.indexOf(col))
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    _sortAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 14,
                                    color: HorizonColors.textTertiary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        onSort: widget.sortable
                            ? (columnIndex, ascending) {
                                setState(() {
                                  if (_sortColumnIndex == columnIndex) {
                                    _sortAscending = !_sortAscending;
                                  } else {
                                    _sortColumnIndex = columnIndex;
                                    _sortAscending = true;
                                  }
                                });
                              }
                            : null,
                      ),
                    )
                    .toList(),
                rows: widget.rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final isSelected = _selectedRows.contains(index);

                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedRows.add(index);
                        } else {
                          _selectedRows.remove(index);
                        }
                      });
                    },
                    cells: row.cells,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Horizon Design System - Data Table Helper
/// Static helper to create properly formatted table cells
class HorizonTableCell extends StatelessWidget {
  final String text;
  final TextAlign align;
  final FontWeight fontWeight;
  final bool isNumeric;

  const HorizonTableCell(
    this.text, {
    super.key,
    this.align = TextAlign.left,
    this.fontWeight = FontWeight.normal,
    this.isNumeric = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isNumeric
        ? HorizonTypography.tabularNumbers(
            Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: HorizonColors.textPrimary,
                  fontWeight: fontWeight,
                ),
          )
        : Theme.of(context).textTheme.bodySmall?.copyWith(
              color: HorizonColors.textPrimary,
              fontWeight: fontWeight,
            );

    return Text(
      text,
      textAlign: align,
      style: style,
    );
  }
}

/// Horizon Status Cell with indicator
class HorizonStatusCell extends StatelessWidget {
  final String status;
  final Color? color;

  const HorizonStatusCell(
    this.status, {
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors['indicator'],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors['text'],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getStatusColor() {
    final normalized = status.toLowerCase();
    final bgColor = color ?? HorizonColors.surfaceGrey;

    if (normalized.contains('in stock') || normalized.contains('active')) {
      return {
        'background': HorizonColors.emerald.withOpacity(0.1),
        'indicator': HorizonColors.emerald,
        'text': HorizonColors.emeraldDark,
      };
    }

    if (normalized.contains('low stock')) {
      return {
        'background': HorizonColors.amber.withOpacity(0.1),
        'indicator': HorizonColors.amber,
        'text': HorizonColors.amberDark,
      };
    }

    if (normalized.contains('out of stock')) {
      return {
        'background': HorizonColors.rose.withOpacity(0.1),
        'indicator': HorizonColors.rose,
        'text': HorizonColors.roseDark,
      };
    }

    return {
      'background': bgColor,
      'indicator': HorizonColors.textTertiary,
      'text': HorizonColors.textSecondary,
    };
  }
}
