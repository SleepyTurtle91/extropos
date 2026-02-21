import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced quantity control widget with validation and proper UX
class QuantityControl extends StatelessWidget {
  final int quantity;
  final int minQuantity;
  final int maxQuantity;
  final ValueChanged<int> onQuantityChanged;
  final bool enabled;
  final double size;

  const QuantityControl({
    super.key,
    required this.quantity,
    this.minQuantity = 0,
    this.maxQuantity = 999,
    required this.onQuantityChanged,
    this.enabled = true,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDecrement = enabled && quantity > minQuantity;
    final canIncrement = enabled && quantity < maxQuantity;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          SizedBox(
            width: size,
            height: size,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.remove,
                size: size * 0.6,
                color: canDecrement ? theme.primaryColor : theme.disabledColor,
              ),
              onPressed: canDecrement
                  ? () => onQuantityChanged(quantity - 1)
                  : null,
              tooltip: 'Decrease quantity',
            ),
          ),

          // Quantity display/input
          Container(
            width: size * 2,
            height: size,
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Increment button
          SizedBox(
            width: size,
            height: size,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.add,
                size: size * 0.6,
                color: canIncrement ? theme.primaryColor : theme.disabledColor,
              ),
              onPressed: canIncrement
                  ? () => onQuantityChanged(quantity + 1)
                  : null,
              tooltip: 'Increase quantity',
            ),
          ),
        ],
      ),
    );
  }
}

/// Advanced quantity control with direct input capability
class AdvancedQuantityControl extends StatefulWidget {
  final int quantity;
  final int minQuantity;
  final int maxQuantity;
  final ValueChanged<int> onQuantityChanged;
  final bool enabled;
  final double size;

  const AdvancedQuantityControl({
    super.key,
    required this.quantity,
    this.minQuantity = 0,
    this.maxQuantity = 999,
    required this.onQuantityChanged,
    this.enabled = true,
    this.size = 32.0,
  });

  @override
  State<AdvancedQuantityControl> createState() => _AdvancedQuantityControlState();
}

class _AdvancedQuantityControlState extends State<AdvancedQuantityControl> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(AdvancedQuantityControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity && !_isEditing) {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isEditing = _focusNode.hasFocus;
    });

    if (!_focusNode.hasFocus) {
      // Validate and apply the input when focus is lost
      _applyInput();
    }
  }

  void _applyInput() {
    final text = _controller.text.trim();
    final parsed = int.tryParse(text);

    if (parsed != null) {
      final clamped = parsed.clamp(widget.minQuantity, widget.maxQuantity);
      if (clamped != widget.quantity) {
        widget.onQuantityChanged(clamped);
      }
    } else {
      // Invalid input, revert to current quantity
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDecrement = widget.enabled && widget.quantity > widget.minQuantity;
    final canIncrement = widget.enabled && widget.quantity < widget.maxQuantity;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.remove,
                size: widget.size * 0.6,
                color: canDecrement ? theme.primaryColor : theme.disabledColor,
              ),
              onPressed: canDecrement
                  ? () => widget.onQuantityChanged(widget.quantity - 1)
                  : null,
              tooltip: 'Decrease quantity',
            ),
          ),

          // Quantity input field
          Container(
            width: widget.size * 2.5,
            height: widget.size,
            alignment: Alignment.center,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3), // Max 3 digits
              ],
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: (_) => _applyInput(),
            ),
          ),

          // Increment button
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.add,
                size: widget.size * 0.6,
                color: canIncrement ? theme.primaryColor : theme.disabledColor,
              ),
              onPressed: canIncrement
                  ? () => widget.onQuantityChanged(widget.quantity + 1)
                  : null,
              tooltip: 'Increase quantity',
            ),
          ),
        ],
      ),
    );
  }
}