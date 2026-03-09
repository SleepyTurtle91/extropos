# POS UI & Responsive Design Expertise

**Skill Domain**: Build responsive, adaptive POS interfaces that work seamlessly on Windows, Android tablets, and various screen sizes

**When to Invoke**: Creating screens and widgets, responsive design issues, touch target optimization, layout improvements, multi-screen support

---

## Core UI Areas

### 1. Responsive Grid Pattern (Mandatory for All Lists)

**Pattern**: Always use `LayoutBuilder` with adaptive columns

```dart
// ✅ CORRECT: Responsive grid that adapts to screen size
class ProductGridWidget extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductSelected;
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        double itemHeight = 160;
        
        // Adaptive breakpoints
        if (constraints.maxWidth < 600) {
          columns = 1;
          itemHeight = 120;
        } else if (constraints.maxWidth < 900) {
          columns = 2;
          itemHeight = 140;
        } else if (constraints.maxWidth < 1200) {
          columns = 3;
          itemHeight = 150;
        }
        
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 1.0,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: products[index],
              onTap: () => onProductSelected(products[index]),
            );
          },
        );
      },
    );
  }
}

// ❌ WRONG: Fixed column count breaks on resize
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4, // ❌ Always 4, breaks on small screens!
  ),
  // ...
)
```

**Breakpoint System**:
- Mobile: < 600px (1 column, portrait orientation)
- Tablet: 600-900px (2-3 columns, landscape possible)
- Desktop Small: 900-1200px (3-4 columns)
- Desktop Large: > 1200px (4+ columns, larger items)

**Implementation Checklist**:
- [ ] All product grids use `LayoutBuilder`
- [ ] Adaptive column count based on width
- [ ] Item height adjusts per breakpoint
- [ ] Spacing scales appropriately
- [ ] Text doesn't overflow on mobile
- [ ] Touch targets >= 48x48 dp

### 2. Touch Target Optimization

**Minimum Sizes** (Following Material Design):
- Button: 48x48 dp minimum
- Icon Button: 48x48 dp
- Spacing between targets: 8 dp minimum

```dart
// ✅ CORRECT: Large touch targets for POS
class CartItemCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12), // Adequate padding
        child: Row(
          children: [
            Column(
              children: [
                Text('Product Name'),
                Text('RM 50.00'),
              ],
            ),
            Spacer(),
            // ✅ 48x48 minimum tap targets
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                icon: Icon(Icons.remove),
                onPressed: () => decreaseQuantity(),
              ),
            ),
            Container(
              width: 60,
              alignment: Alignment.center,
              child: Text('2'), // Quantity display
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                icon: Icon(Icons.add),
                onPressed: () => increaseQuantity(),
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => removeItem(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ❌ WRONG: Too small touch targets
IconButton(
  icon: Icon(Icons.add), // Default 24x24 - too small!
  // No explicit size
  onPressed: () => increaseQuantity(),
)
```

### 3. Text Overflow & Ellipsis Handling

**Rule**: Always handle text overflow in constrained spaces

```dart
// ✅ CORRECT: Handles text overflow
class ProductNameDisplay extends StatelessWidget {
  final String productName;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          productName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          'RM 99.99',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}

// ❌ WRONG: Text can overflow or cause layout issues
Text(productName) // No overflow handling
```

### 4. Scrollable Dialogs & Forms

**Pattern**: Use `ConstrainedBox` + `SingleChildScrollView` for scrollable content

```dart
// ✅ CORRECT: Scrollable, constrained dialog
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
            AppBar(title: Text('Product Details')),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Product Name'),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Price'),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Category'),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'More Fields...'),
                  ),
                  // ... more fields
                  SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(onPressed: save, child: Text('Save')),
                      ElevatedButton(onPressed: cancel, child: Text('Cancel')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

// ❌ WRONG: Dialog can overflow screen
showDialog(
  context: context,
  builder: (_) => Dialog(
    child: Column(
      children: [
        // Many fields without scroll or constraint
        // Dialog could be taller than screen!
      ],
    ),
  ),
);
```

### 5. Platform-Specific Layouts

**Windows Desktop** (Primary platform):
- Wide screens (1920x1080 typical)
- Mouse/keyboard input
- Large click areas acceptable
- Multi-column layouts
- Bottom navigation bar or side menu

```dart
// ✅ CORRECT: Desktop-optimized POS screen
class RetailPOSScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: DesktopAppBar(),
      ),
      body: Row(
        children: [
          // Left sidebar: Categories
          Container(
            width: 200,
            color: Colors.grey[200],
            child: CategoryList(),
          ),
          // Center: Product grid
          Expanded(
            flex: 2,
            child: ProductGrid(),
          ),
          // Right sidebar: Cart
          Container(
            width: 300,
            child: CartPanel(),
          ),
        ],
      ),
    );
  }
}
```

**Android Tablet** (Secondary platform):
- Medium screens (600-1000 width)
- Touch-first interaction
- Portrait or landscape
- Stack-based navigation

```dart
// ✅ CORRECT: Tablet-responsive POS
class RetailPOSScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final isLandscape = 
      MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Scaffold(
      body: isLandscape
          ? Row(
              children: [
                Expanded(flex: 2, child: ProductGrid()),
                Expanded(flex: 1, child: CartPanel()),
              ],
            )
          : Column(
              children: [
                Expanded(child: ProductGrid()),
                Expanded(child: CartPanel()),
              ],
            ),
    );
  }
}
```

### 6. Landscape vs Portrait Orientation

**Implementation Pattern**:

```dart
// ✅ CORRECT: Responsive to orientation
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    
    if (orientation == Orientation.portrait) {
      return PortraitLayout();
    } else {
      return LandscapeLayout();
    }
  }
}

// Or using OrientationBuilder
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return orientation == Orientation.portrait
            ? PortraitLayout()
            : LandscapeLayout();
      },
    );
  }
}
```

### 7. POS Mode-Specific UI Patterns

**Retail Mode**:
- Category sidebar or tab navigation
- Product grid (4 columns on desktop, 2 on mobile)
- Cart on right side (desktop) or bottom (mobile)
- Quick add/remove buttons

**Cafe Mode**:
- Category icons (drinks, food, pastries)
- Modifiers selection (size, temperature, syrup)
- Cart display with modifications
- Tender calculation for quick payment

**Restaurant Mode**:
- Table selection grid first
- Order management per table
- Serve/Unserve tracking
- Merge table functionality

```dart
// ✅ CORRECT: Mode-specific UI routing
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

### 8. Visual Hierarchy & Layout

**Principle**: Most important elements are largest and most prominent

```dart
// ✅ CORRECT: Clear visual hierarchy
class CartSummaryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Least important: Details
        Text(
          'Cart Summary',
          style: theme.textTheme.bodySmall,
          color: Colors.grey[700],
        ),
        SizedBox(height: 8),
        
        // Important: Item count
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '5 ',
                style: theme.textTheme.headlineSmall,
              ),
              TextSpan(
                text: 'items',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        
        // MOST important: Total amount
        Text(
          'RM 250.50',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      ],
    );
  }
}
```

### 9. Button Layout & Spacing

**Patterns**:

```dart
// ✅ CORRECT: Buttons with good spacing
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    OutlinedButton(onPressed: cancel, child: Text('Cancel')),
    ElevatedButton(onPressed: submit, child: Text('Submit')),
  ],
)

// ✅ CORRECT: Button bar for multiple actions
ButtonBar(
  mainAxisSize: MainAxisSize.min,
  children: [
    TextButton(onPressed: clear, child: Text('Clear')),
    ElevatedButton(onPressed: save, child: Text('Save')),
  ],
)

// ❌ WRONG: Buttons squished together
Row(
  children: [
    ElevatedButton(onPressed: cancel, child: Text('No')),
    ElevatedButton(onPressed: submit, child: Text('Yes')),
  ],
)
```

### 10. Color & Theming for POS

**POS-Specific Colors**:
- Success (Green): Payments, savings, actions complete
- Warning (Amber): Inventory low, payment verification
- Error (Red): Failed transactions, invalid input
- Info (Blue): Informational messages, help text
- Neutral (Gray): Disabled, secondary content

```dart
// ✅ CORRECT: Semantic color usage
class PaymentStatusIndicator extends StatelessWidget {
  final bool isPaid;
  final bool isPending;
  
  @override
  Widget build(BuildContext context) {
    final color = isPaid
        ? Colors.green[700]
        : isPending
            ? Colors.amber[700]
            : Colors.red[700];
    
    final icon = isPaid
        ? Icons.check_circle
        : isPending
            ? Icons.hourglass_bottom
            : Icons.close_circle;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1),
        border: Border.all(color: color!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8),
          Text(
            isPaid ? 'Paid' : isPending ? 'Pending' : 'Unpaid',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
```

### 11. Widget Composition & Depth

**Rule**: Keep widget trees shallow (< 10 levels deep)

```dart
// ✅ CORRECT: Well-decomposed, shallow widget tree
class CartItemCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(/* short build */);
}

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

class CartScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(/* ... */),
    body: CartPanel(),
  );
}

// ❌ WRONG: Deeply nested, monolithic widget
class CartScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(/* ... */),
    body: Column(
      children: [
        Row(
          children: [
            Text('Cart'),
            IconButton(onPressed: () {}, icon: Icon(Icons.close)),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemBuilder: (context, index) => Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(/* ... 5 more levels */),
              ),
            ),
          ),
        ),
        Container(
          color: Colors.grey[200],
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                children: [
                  Text('Total: RM 250'),
                  Text('Pay Now'),
                ],
              ),
              ElevatedButton(onPressed: () {}, child: Text('Checkout')),
            ],
          ),
        ),
      ],
    ),
  );
}
```

### 12. Performance: Avoid Rebuilds

**Anti-Patterns**:

```dart
// ❌ WRONG: Rebuilds entire cart on any state change
class CartPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Everything rebuilds when cartTotal changes
    return Column(
      children: [
        CartItems(), // Rebuilds
        CartTotal(), // Rebuilds
        CheckoutButton(), // Rebuilds
      ],
    );
  }
}

// ✅ CORRECT: Only rebuild affected widgets
class CartPanel extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: CartItems()), // Only rebuilds when items change
        CartTotal(total: cartTotal), // Only rebuilds when total changes
        CheckoutButton(onPressed: checkout), // Only rebuilds when enabled changes
      ],
    );
  }
}
```

---

## Quick Reference: When This Skill Applies

✅ **Invoke This Skill For**:
- Creating new screens or widgets
- Responsive grid issues
- Layout problems on different screen sizes
- Touch target optimization
- Dialog and form scrolling
- Multi-orientation support
- Color and theming decisions
- Widget composition and decomposition
- Performance optimization (rebuild issues)
- POS mode-specific UI patterns
- Button and spacing layout

❌ **Don't Use For**:
- Business logic (use POS Business Logic skill)
- State management architecture (use Flutter Architecture skill)
- Database operations
- Animation and transitions (use standard Flutter docs)

---

## Testing UI Components

```dart
// test/widgets/cart_item_card_test.dart

void main() {
  group('CartItemCard', () {
    testWidgets('displays product name and price', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemCard(
              item: CartItem(
                product: Product(name: 'Coffee', price: 5.50),
                quantity: 2,
              ),
              onQuantityChanged: (_) {},
              onRemove: () {},
            ),
          ),
        ),
      );
      
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('RM 5.50'), findsOneWidget);
    });
    
    testWidgets('calls onQuantityChanged when + button pressed', 
        (WidgetTester tester) async {
      int? newQuantity;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemCard(
              item: CartItem(...),
              onQuantityChanged: (qty) => newQuantity = qty,
              onRemove: () {},
            ),
          ),
        ),
      );
      
      await tester.tap(find.byIcon(Icons.add));
      expect(newQuantity, equals(3)); // Was 2, now 3
    });
  });
}
```

---

## Integration with Your Project

**Existing POS Screens**:
- `lib/screens/retail_pos_screen_modern.dart` - Retail mode with adaptive layout
- `lib/screens/cafe_pos_screen.dart` - Cafe mode with modifiers
- `lib/screens/restaurant_table_screen.dart` - Table-based ordering

**Responsive Components**:
- `lib/widgets/product_grid.dart` - Adaptive product display
- `lib/widgets/cart_panel.dart` - Cart sidebar/bottom sheet
- `lib/widgets/payment_dialog.dart` - Payment method selection

**Theme System**:
- Material 3 design tokens
- Custom color scheme for POS (success/warning/error)
- Optimized for 58mm/80mm thermal receipts

