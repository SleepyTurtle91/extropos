---
name: pos-ui-responsive-design
description: Build responsive POS interfaces for Windows desktop and Android tablets. Implement adaptive layouts with LayoutBuilder, optimize touch targets (48x48 dp), handle text overflow, create responsive grids, and support multiple screen orientations.
license: Proprietary
compatibility: Flutter 3.0+, Dart 3.0+. Designed for Windows desktop (1920x1080) and Android tablets (600-1200 width).
metadata:
  author: FlutterPOS
  version: "1.0"
  domain: flutter-dart
  focus: ui-design
---

# POS UI & Responsive Design

**When to use this skill**: Building screens, layout problems on different sizes, responsive grids, touch optimization, adaptive dialogs, multi-orientation support.

## Responsive Grid Pattern (MANDATORY)

Always use `LayoutBuilder` with adaptive columns:

```dart
class ProductGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        
        if (constraints.maxWidth < 600) columns = 1;
        else if (constraints.maxWidth < 900) columns = 2;
        else if (constraints.maxWidth < 1200) columns = 3;
        
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: /* ... */,
        );
      },
    );
  }
}
```

**Breakpoints**:
- < 600px: 1 column (mobile)
- 600-900px: 2 columns (small tablet)
- 900-1200px: 3 columns (large tablet)
- > 1200px: 4 columns (desktop)

## Touch Target Optimization

Minimum sizes (Material Design):
- Buttons: 48x48 dp
- Icon buttons: 48x48 dp
- Spacing: 8 dp minimum

```dart
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: Icon(Icons.add),
    onPressed: () => increaseQuantity(),
  ),
)
```

## Text Overflow Handling

Always handle text overflow in constrained spaces:

```dart
Text(
  productName,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: Theme.of(context).textTheme.bodyMedium,
)
```

## Scrollable Dialogs

Use `ConstrainedBox` + `SingleChildScrollView`:

```dart
showDialog(
  context: context,
  builder: (_) => Dialog(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        maxWidth: 500,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /* content */
          ],
        ),
      ),
    ),
  ),
);
```

## Orientation Support

Respond to orientation changes:

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isLandscape = 
      MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Scaffold(
      body: isLandscape
          ? Row(children: [/* landscape layout */])
          : Column(children: [/* portrait layout */]),
    );
  }
}
```

## Widget Tree Depth

**Rule**: Keep widget trees shallow (< 10 levels deep)

✅ **Correct**: Well-composed, separate widgets
```dart
class CartPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      CartHeader(),
      Expanded(child: CartItemsList()),
      CartFooter(),
    ],
  );
}
```

❌ **Wrong**: Deeply nested monolithic widget
```dart
class CartPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(children: [Text(...), IconButton(...)]), // 3 levels
      Expanded(child: ListView.builder(
        itemBuilder: (context, index) => Card(
          child: Padding(child: Row(...)), // 7+ levels
        ),
      )),
      /* footer */
    ],
  );
}
```

## POS Mode-Specific Layouts

### Retail Mode
- Category sidebar + product grid + cart panel (desktop)
- Stacked layout (mobile)
- Quick add/remove buttons

### Cafe Mode
- Category icons
- Modifier selection
- Cart with modifications
- Quick payment

### Restaurant Mode
- Table selection grid first
- Order management per table
- Merge/split functionality

```dart
class UnifiedPOSScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mode = BusinessInfo.instance.selectedBusinessMode;
    
    return switch (mode) {
      BusinessMode.retail => RetailPOSScreenModern(),
      BusinessMode.cafe => CafePOSScreen(),
      BusinessMode.restaurant => RestaurantTableScreen(),
    };
  }
}
```

## Visual Hierarchy

Most important elements are largest and most prominent:

```dart
Column(
  children: [
    // Least important
    Text('Cart Summary', style: bodySmall),
    SizedBox(height: 8),
    
    // Important
    Text('5 items', style: headline6),
    SizedBox(height: 12),
    
    // MOST important
    Text('RM 250.50', style: headlineMedium.bold),
  ],
)
```

## Platform Considerations

**Windows Desktop** (Primary):
- 1920x1080 typical
- Mouse/keyboard
- Multi-column layouts
- Bottom navigation

**Android Tablet** (Secondary):
- 600-1000 width
- Portrait/landscape
- Touch-first
- Stack-based navigation

---

See [references/UI_PATTERNS.md](references/UI_PATTERNS.md) for complete component patterns.

See [references/RESPONSIVE_EXAMPLES.md](references/RESPONSIVE_EXAMPLES.md) for working examples.
