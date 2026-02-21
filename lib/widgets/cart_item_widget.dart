import 'package:extropos/models/cart_item.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:extropos/widgets/dialog_helpers.dart';
import 'package:flutter/material.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;
  final ValueChanged<double>? onSetDiscount;
  final ValueChanged<String?>? onSetNotes;
  final int? tableCapacity;
  final ValueChanged<int?>? onSetSeat;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onAdd,
    this.onEdit,
    this.onSetDiscount,
    this.onSetNotes,
    this.tableCapacity,
    this.onSetSeat,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a slightly larger threshold because cart sidebars can be small
        final bool isNarrow = constraints.maxWidth < 350;
        final theme = Theme.of(context);
        final hasModifiers = item.modifiers.isNotEmpty;
        final modifiersDisplay = hasModifiers
            ? item.modifiers
                  .map(
                    (m) => m.priceAdjustment == 0
                        ? m.name
                        : '${m.name} (${m.getPriceAdjustmentDisplay()})',
                  )
                  .join(', ')
            : '';

        // Build the vertical layout (compact), otherwise keep row layout
        if (isNarrow) {
          final theme = Theme.of(context);
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.getFullDisplayName(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  if (item.selectedVariant != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.selectedVariant!.name,
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  if (hasModifiers) ...[
                    const SizedBox(height: 6),
                    Text(
                      modifiersDisplay,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Note: ${item.notes}',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: onRemove,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 20,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: onAdd,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 20,
                          ),
                        ],
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 72),
                        child: Text(
                          'RM ${item.totalPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.event_seat),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                          maxWidth: 36,
                          maxHeight: 36,
                        ),
                        onPressed: onSetSeat == null || tableCapacity == null
                            ? null
                            : () async {
                                final selected = await showDialog<int?>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Assign Seat'),
                                      content: ConstrainedDialog(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: tableCapacity!,
                                              itemBuilder: (_, idx) {
                                                final seat = idx + 1;
                                                return ListTile(
                                                  title: Text('Seat $seat'),
                                                  trailing:
                                                      item.seatNumber == seat
                                                      ? const Icon(Icons.check)
                                                      : null,
                                                  onTap: () => Navigator.of(
                                                    context,
                                                  ).pop(seat),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(null),
                                          child: const Text('None'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (selected != null) onSetSeat?.call(selected);
                                if (selected == null) onSetSeat?.call(null);
                              },
                      ),
                      if (item.seatNumber != null)
                        Text(
                          'Seat ${item.seatNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.local_offer_outlined),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                          maxWidth: 36,
                          maxHeight: 36,
                        ),
                        onPressed: onSetDiscount == null
                            ? null
                            : () async {
                                final controller = TextEditingController(
                                  text: item.discountPerUnit.toStringAsFixed(2),
                                );
                                final res = await showDialog<double?>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Set discount (RM)'),
                                    content: TextField(
                                      controller: controller,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        hintText: '0.00',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          final v =
                                              double.tryParse(
                                                controller.text,
                                              ) ??
                                              0.0;
                                          Navigator.of(context).pop(v);
                                        },
                                        child: const Text('Apply'),
                                      ),
                                    ],
                                  ),
                                );
                                if (res != null) onSetDiscount?.call(res);
                              },
                      ),
                      if (item.discountPerUnit > 0)
                        Text(
                          'RM ${item.discountPerUnit.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.note_add_outlined),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                          maxWidth: 36,
                          maxHeight: 36,
                        ),
                        onPressed: onSetNotes == null
                            ? null
                            : () async {
                                final controller = TextEditingController(
                                  text: item.notes ?? '',
                                );
                                final res = await showDialog<String?>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Add Note'),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Enter special instructions...',
                                      ),
                                      maxLines: 3,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          final note = controller.text.trim();
                                          Navigator.of(
                                            context,
                                          ).pop(note.isEmpty ? null : note);
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                                if (res != null) onSetNotes?.call(res);
                              },
                      ),
                      if (item.notes != null && item.notes!.isNotEmpty)
                        const Icon(Icons.note, size: 16, color: Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Default row layout (existing behavior) for wider widths
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.getFullDisplayName(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      if (item.selectedVariant != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.selectedVariant!.name,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      if (hasModifiers) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                modifiersDisplay,
                                style: theme.cardCaption.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            if (onEdit != null)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                onPressed: onEdit,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                  maxWidth: 36,
                                  maxHeight: 36,
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'RM ${item.finalPrice.toStringAsFixed(2)}${hasModifiers ? ' (base: RM ${item.product.price.toStringAsFixed(2)})' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                      if (item.discountPerUnit > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Discount: RM ${item.discountPerUnit.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Note: ${item.notes}',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: onRemove,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s,
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: onAdd,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.m),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 72,
                    maxWidth: 160,
                  ),
                  child: Text(
                    'RM ${item.totalPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.event_seat),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                        maxWidth: 36,
                        maxHeight: 36,
                      ),
                      onPressed: onSetSeat == null || tableCapacity == null
                          ? null
                          : () async {
                              final selected = await showDialog<int?>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Assign Seat'),
                                  content: ConstrainedDialog(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: tableCapacity!,
                                      itemBuilder: (_, idx) {
                                        final seat = idx + 1;
                                        return ListTile(
                                          title: Text('Seat $seat'),
                                          trailing: item.seatNumber == seat
                                              ? const Icon(Icons.check)
                                              : null,
                                          onTap: () =>
                                              Navigator.of(context).pop(seat),
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(null),
                                      child: const Text('None'),
                                    ),
                                  ],
                                ),
                              );
                              if (selected != null) onSetSeat?.call(selected);
                              if (selected == null) onSetSeat?.call(null);
                            },
                    ),
                    if (item.seatNumber != null)
                      Text(
                        'Seat ${item.seatNumber}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )
                    else
                      const SizedBox.shrink(),
                    IconButton(
                      icon: const Icon(Icons.local_offer_outlined),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                        maxWidth: 36,
                        maxHeight: 36,
                      ),
                      onPressed: onSetDiscount == null
                          ? null
                          : () async {
                              final controller = TextEditingController(
                                text: item.discountPerUnit.toStringAsFixed(2),
                              );
                              final res = await showDialog<double?>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Set discount (RM)'),
                                  content: TextField(
                                    controller: controller,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      hintText: '0.00',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        final v =
                                            double.tryParse(controller.text) ??
                                            0.0;
                                        Navigator.of(context).pop(v);
                                      },
                                      child: const Text('Apply'),
                                    ),
                                  ],
                                ),
                              );
                              if (res != null) onSetDiscount?.call(res);
                            },
                    ),
                    if (item.discountPerUnit > 0)
                      Text(
                        'RM ${item.discountPerUnit.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      )
                    else
                      const SizedBox.shrink(),
                    IconButton(
                      icon: const Icon(Icons.note_add_outlined),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                        maxWidth: 36,
                        maxHeight: 36,
                      ),
                      onPressed: onSetNotes == null
                          ? null
                          : () async {
                              final controller = TextEditingController(
                                text: item.notes ?? '',
                              );
                              final res = await showDialog<String?>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Add Note'),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter special instructions...',
                                    ),
                                    maxLines: 3,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        final note = controller.text.trim();
                                        Navigator.of(
                                          context,
                                        ).pop(note.isEmpty ? null : note);
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              );
                              if (res != null) onSetNotes?.call(res);
                            },
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      const Icon(Icons.note, size: 16, color: Colors.orange)
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
