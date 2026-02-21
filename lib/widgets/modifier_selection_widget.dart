import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/modifier_group_model.dart';
import 'package:extropos/models/modifier_item_model.dart';
import 'package:flutter/material.dart';

class ModifierSelectionWidget extends StatefulWidget {
  final ModifierGroup group;
  final List<ModifierItem> items;
  final List<String> selectedIds;
  final Function(List<String>) onSelectionChanged;

  const ModifierSelectionWidget({
    super.key,
    required this.group,
    required this.items,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<ModifierSelectionWidget> createState() =>
      _ModifierSelectionWidgetState();
}

class _ModifierSelectionWidgetState extends State<ModifierSelectionWidget> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  void _onItemSelected(String itemId, bool selected) {
    setState(() {
      if (widget.group.allowMultiple) {
        // Multiple selection
        if (selected) {
          if (!_selectedIds.contains(itemId)) {
            _selectedIds.add(itemId);
          }
        } else {
          _selectedIds.remove(itemId);
        }

        // Check max selection limit
        if (widget.group.maxSelection != null &&
            _selectedIds.length > widget.group.maxSelection!) {
          _selectedIds.removeLast();
          return;
        }
      } else {
        // Single selection
        _selectedIds = selected ? [itemId] : [];
      }
    });

    widget.onSelectionChanged(_selectedIds);
  }

  bool _isValidSelection() {
    final minSelection = widget.group.minSelection ?? 0;
    final maxSelection = widget.group.maxSelection;

    if (_selectedIds.length < minSelection) return false;
    if (maxSelection != null && _selectedIds.length > maxSelection)
      return false;

    return true;
  }

  String _getSelectionHint() {
    final minSelection = widget.group.minSelection ?? 0;
    final maxSelection = widget.group.maxSelection;

    if (widget.group.isRequired && minSelection > 0) {
      if (maxSelection != null && maxSelection != minSelection) {
        return 'Choose $minSelection-$maxSelection options (required)';
      } else if (maxSelection == 1) {
        return 'Choose 1 option (required)';
      } else {
        return 'Choose at least $minSelection options (required)';
      }
    } else if (maxSelection != null) {
      return 'Choose up to $maxSelection options';
    } else {
      return 'Optional';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isValidSelection() ? Colors.grey[300]! : Colors.red[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.group.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.group.isRequired) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.group.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.group.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _getSelectionHint(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _isValidSelection()
                        ? Colors.grey[500]
                        : Colors.red[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Modifier Items
          ...widget.items.map((item) => _buildModifierItem(item)),
        ],
      ),
    );
  }

  Widget _buildModifierItem(ModifierItem item) {
    final isSelected = _selectedIds.contains(item.id);
    final priceText = item.priceAdjustment != 0
        ? ' ${item.priceAdjustment > 0 ? '+' : ''}${BusinessInfo.instance.currencySymbol}${item.priceAdjustment.toStringAsFixed(2)}'
        : '';

    return InkWell(
      onTap: () => _onItemSelected(item.id, !isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: Row(
          children: [
            // Selection Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),

            const SizedBox(width: 12),

            // Item Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (priceText.isNotEmpty)
                        Text(
                          priceText,
                          style: TextStyle(
                            fontSize: 14,
                            color: item.priceAdjustment >= 0
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),

            // Icon if available
            if (item.icon != null) ...[
              const SizedBox(width: 8),
              Icon(item.icon, size: 20, color: item.color ?? Colors.grey[600]),
            ],
          ],
        ),
      ),
    );
  }
}
