# Responsive Layout Quick Reference

One-page cheat sheet for responsive patterns in FlutterPOS

---

## ResponsiveRow Widget

**Location**: `lib/widgets/responsive_row.dart`

```dart
ResponsiveRow(
  breakpoint: 480,  // Optional, defaults to 700
  rowChildren: [
    Expanded(child: TextField(...)),
    SizedBox(width: 16),
    Expanded(child: DropdownButtonFormField(...)),
  ],
  columnChildren: [
    TextField(...),
    SizedBox(height: 16),
    DropdownButtonFormField(...),
  ],
)

```text

**When to Use**: Repeated form layouts with 2+ horizontal inputs

---


## LayoutBuilder Pattern



```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 700) {
      return Column(
        children: [
          Widget1(),
          SizedBox(height: 16),
          Widget2(),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: Widget1()),
        SizedBox(width: 16),
        Expanded(child: Widget2()),
      ],
    );
  },
)

```text

**When to Use**: Single-use responsive section

---


## Wrap Pattern



```dart
Wrap(
  spacing: 16,
  runSpacing: 16,
  alignment: WrapAlignment.center,
  children: [
    Card(...),
    Card(...),
    Card(...),
  ],
)

```text

**When to Use**: Cards/tiles that should auto-wrap

---


## CustomScrollView Pattern



```dart
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(
      child: StaticWidget(),
    ),
    SliverToBoxAdapter(
      child: AnotherStaticWidget(),
    ),
    SliverFillRemaining(
      child: ScrollableContent(),
    ),
  ],
)

```text

**When to Use**: Mixed static + scrollable content

---


## Breakpoints Used in FlutterPOS


|Size|Breakpoint|Use Case|
|----|----------|---------|
|360px|Narrow phone|KeyGen dropdown, minimum supported|
|480px|Phone portrait|Table capacity/status|
|520px|Phone landscape|Printer USB device|
|560px|Small tablet|Printer IP/port|
|700px|Tablet/laptop|Search filters, ResponsiveRow default|
|1366px|Desktop|Primary target|

---


## Screen Size Targets


- **360x800** - Phone portrait (minimum)

- **812x375** - Phone landscape

- **800x1280** - Tablet portrait

- **1366x768** - Laptop (primary target)

- **1920x1080** - Desktop

- **2560x1440** - 2K display

- **3840x2160** - 4K display

---


## Common Issues & Fixes



### Issue: "BOTTOM OVERFLOW BY X PIXELS"


**Fix**: Wrap in `SingleChildScrollView` or use `CustomScrollView`


### Issue: Row overflows horizontally


**Fix**: Use ResponsiveRow or LayoutBuilder to stack on narrow screens


### Issue: Text overflows in constrained space


**Fix**: Wrap in `Flexible` with `overflow: TextOverflow.ellipsis`


### Issue: Cards overflow in Row


**Fix**: Use `Wrap` instead of `Row`


### Issue: Dialog overflow on small screens


**Fix**: Wrap content in `ConstrainedBox` + `SingleChildScrollView`

---


## Test Commands



```bash

# Run all tests

flutter test


# Update golden files (baseline screenshots)

flutter test --update-goldens


# Run specific test file

flutter test test/visual/responsive_screens_test.dart


# Run with verbose output

flutter test --reporter expanded

```text

---


## Files Using Each Pattern



### ResponsiveRow


- `lib/screens/printers_management_screen.dart` (USB, Network)

- `lib/screens/tables_management_screen.dart` (Capacity/Status)


### LayoutBuilder


- `lib/screens/items_management_screen.dart` (Search + Filter)

- `lib/screens/keygen_home_screen.dart` (Number of Keys)


### Wrap


- `lib/screens/mode_selection_screen.dart` (Mode cards)


### CustomScrollView


- `lib/screens/kitchen_display_screen.dart` (Stats + Orders)

---


## Quick Decision Tree



```text
Need responsive layout?
│
├─ Repeated pattern (2+ screens)?

│  └─ Use ResponsiveRow widget
│
├─ Single-use section?
│  └─ Use LayoutBuilder
│
├─ Cards that should wrap?
│  └─ Use Wrap
│
├─ Mixed static + scrollable?

│  └─ Use CustomScrollView
│
└─ Just need flexible sizing?
   └─ Use ConstrainedBox

```text

---


## Code Snippets



### Responsive TextField + Button



```dart
ResponsiveRow(
  breakpoint: 520,
  rowChildren: [
    Expanded(flex: 3, child: TextField(...)),
    SizedBox(width: 16),
    Expanded(child: ElevatedButton(...)),
  ],
  columnChildren: [
    TextField(...),
    SizedBox(height: 16),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(...),
    ),
  ],
)

```text


### Responsive Two TextFields



```dart
ResponsiveRow(
  breakpoint: 480,
  rowChildren: [
    Expanded(child: TextField(/* Field 1 */)),
    SizedBox(width: 16),
    Expanded(child: TextField(/* Field 2 */)),
  ],
  columnChildren: [
    TextField(/* Field 1 */),
    SizedBox(height: 16),
    TextField(/* Field 2 */),
  ],
)

```text


### Responsive Label + Dropdown



```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 360) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Label:'),
          SizedBox(height: 8),
          DropdownButtonFormField(...),
        ],
      );
    }
    return Row(
      children: [
        Text('Label:'),
        SizedBox(width: 16),
        Expanded(child: DropdownButtonFormField(...)),
      ],
    );
  },
)

```text

---

**Last Updated**: 2025-12-10
