# Modern Reports Dashboard - Visual Reference Guide

## What You Should See

### 📱 Full Dashboard Layout

```text
╔═══════════════════════════════════════════════════════════════╗
║                  Modern Reports Dashboard                      ║
╠═══════════════════════════════════════════════════════════════╣
║                                                                ║
║  ┌─────────────────────────────────────────────────────────┐  ║
║  │ Today │Yesterday│This Week│This Month│Last Month│Custom │  ║
║  └─────────────────────────────────────────────────────────┘  ║
║                                                                ║
║  ┌───────────────┬───────────────┬───────────────┬──────────┐ ║
║  │ 💰 $1,234.56  │ 📈 $1,100.00  │ 🧾 45         │ 🛒 $27.42│ ║
║  │ Gross Sales   │ Net Sales     │ Transactions  │ Avg Ticket║ ║
║  └───────────────┴───────────────┴───────────────┴──────────┘ ║
║                                                                ║
║  Sales Trend (Last 7 Days)                                    ║
║  ┌──────────────────────────────────────────────────────────┐ ║
║  │                           •──•                            │ ║
║  │                      •──•      •──•                       │ ║
║  │               •──•                    •──•                │ ║
║  │        •──•                                               │ ║
║  │                                                           │ ║
║  └──────────────────────────────────────────────────────────┘ ║
║    12/17  12/18  12/19  12/20  12/21  12/22  12/23           ║
║                                                                ║
║  ┌──────────────────────────┬──────────────────────────────┐  ║
║  │  Sales by Category       │  Payment Methods             │  ║
║  │                          │                              │  ║
║  │      ┌─────────┐         │      ┌─────────┐            │  ║
║  │     ╱    🍕    ╲         │     ╱    💳    ╲            │  ║
║  │    │  40%  25% │         │    │  45%  35% │            │  ║
║  │     ╲ 20%  15% ╱         │     ╲    20%   ╱            │  ║
║  │      └─────────┘         │      └─────────┘            │  ║
║  │                          │                              │  ║
║  │  🟢 Food (40%)           │  🔵 Card (45%)               │  ║
║  │  🔵 Beverages (30%)      │  🟢 Cash (35%)               │  ║
║  │  🟠 Desserts (20%)       │  🟣 E-Wallet (20%)           │  ║
║  │  🟣 Merchandise (10%)    │                              │  ║
║  └──────────────────────────┴──────────────────────────────┘  ║
║                                                                ║
║  Top Products                                                  ║
║  ┌──────────────────────────────────────────────────────────┐ ║
║  │ 1. Burger Combo        120 sold • $1,440.00             │ ║
║  │ 2. Iced Coffee         200 sold • $  900.00             │ ║
║  │ 3. Smoothie Bowl       130 sold • $  845.00             │ ║
║  │ 4. Pasta Special        60 sold • $  840.00             │ ║
║  │ 5. Chocolate Cake      110 sold • $  715.00             │ ║
║  └──────────────────────────────────────────────────────────┘ ║
║                                                                ║
║  ┌──────────────────────────────────────────────────────────┐ ║
║  │               📤 Export Report                           │ ║
║  └──────────────────────────────────────────────────────────┘ ║
║                                                                ║
╚═══════════════════════════════════════════════════════════════╝

```

---

## 🎨 Color Palette

### KPI Cards

```text
┌─────────────────┐
│ 💰 $1,234.56    │  ← Green (#10B981)
│ Gross Sales     │     Total revenue before deductions
└─────────────────┘

┌─────────────────┐
│ 📈 $1,100.00    │  ← Blue (#2563EB)
│ Net Sales       │     After tax & discounts
└─────────────────┘

┌─────────────────┐
│ 🧾 45           │  ← Orange (#F97316)
│ Transactions    │     Number of orders
└─────────────────┘

┌─────────────────┐
│ 🛒 $27.42       │  ← Purple (#9333EA)
│ Avg Ticket      │     Revenue per order
└─────────────────┘

```

### Charts

```text
Sales Trend:      Blue line (#2563EB)
Category 1:       Green (#10B981)
Category 2:       Blue (#3B82F6)
Category 3:       Orange (#F59E0B)
Category 4:       Purple (#A855F7)
Payment Cash:     Green (#10B981)
Payment Card:     Blue (#2563EB)
Payment E-Wallet: Purple (#9333EA)

```

---

## 📐 Layout Breakpoints

### Desktop/Tablet (≥600px width)

```text
┌─────────────────────────────────────────────────┐
│ KPI Cards: 4 columns, single row               │
│ ┌─────┬─────┬─────┬─────┐                      │
│ │ KPI │ KPI │ KPI │ KPI │                      │
│ └─────┴─────┴─────┴─────┘                      │
│                                                 │
│ Line Chart: Full width                         │
│ ┌─────────────────────────────────────────┐    │
│ │         Sales Trend                     │    │
│ └─────────────────────────────────────────┘    │
│                                                 │
│ Donut Charts: 2 columns, side by side         │
│ ┌───────────────┬───────────────┐              │
│ │   Category    │   Payment     │              │
│ └───────────────┴───────────────┘              │
└─────────────────────────────────────────────────┘

```

### Mobile (<600px width)

```text
┌─────────────────────────┐
│ KPI Cards: 2 columns    │
│ ┌─────┬─────┐           │
│ │ KPI │ KPI │           │
│ ├─────┼─────┤           │
│ │ KPI │ KPI │           │
│ └─────┴─────┘           │
│                         │
│ Line Chart: Full width  │
│ ┌─────────────────────┐ │
│ │   Sales Trend       │ │
│ └─────────────────────┘ │
│                         │
│ Donut Charts: Stacked   │
│ ┌─────────────────────┐ │
│ │    Category         │ │
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │    Payment          │ │
│ └─────────────────────┘ │
└─────────────────────────┘

```

---

## 🎯 Interactive Elements

### Date Selector Chips

```text
┌─────────────────────────────────────────────────────────┐
│ ┏━━━━━━━┓ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌──────┐│
│ ┃ Today ┃ │Yesterday│ │This Week│ │This Month│ │Custom││
│ ┗━━━━━━━┛ └─────────┘ └─────────┘ └─────────┘ └──────┘│
└─────────────────────────────────────────────────────────┘
     ↑ Selected (Blue background)
         ↑ Unselected (Gray background)

```

**States:**

- **Unselected**: Gray background (#E5E7EB), dark text

- **Selected**: Blue background (#2563EB), white text

- **Hover**: Slight scale animation (desktop)

- **Tap**: Ripple effect, immediate data update

### Pull-to-Refresh

```text
  ┌────────────────────┐
  │  Pull down to      │  ← Pull gesture
  │  refresh...        │
  └────────────────────┘
         ↓↓↓
  ┌────────────────────┐
  │   🔄 Loading...    │  ← Loading state
  └────────────────────┘
         ↓↓↓
  ┌────────────────────┐
  │   Dashboard        │  ← Data refreshed
  │   (Updated)        │
  └────────────────────┘

```

### Export Bottom Sheet

```text
Tap "Export Report" button at bottom:

╔═══════════════════════════════════════╗
║  Choose Export Format                 ║
╠═══════════════════════════════════════╣
║                                       ║
║  ✅ CSV Export                        ║
║  Export data as CSV file              ║
║  ───────────────────────────────      ║
║                                       ║
║  📄 PDF Export        Coming Soon     ║
║  Generate PDF report                  ║
║  ───────────────────────────────      ║
║                                       ║
║  🖨️ Thermal Print     Coming Soon     ║
║  Print to 58mm/80mm printer          ║
║  ───────────────────────────────      ║
║                                       ║
║  [ Cancel ]                           ║
║                                       ║
╚═══════════════════════════════════════╝

```

---

## 📊 Data Examples

### KPI Card Values (with $1000 daily sales)

```text
Gross Sales:    $1,234.56  (Total revenue)
Net Sales:      $1,100.00  (After 10% tax, 1% discount)
Transactions:   45         (Number of orders)
Average Ticket: $27.42     ($1,234.56 ÷ 45)

```

### Line Chart Data Points (7 days)

```text
Day 1: $800
Day 2: $1,100
Day 3: $950
Day 4: $1,300
Day 5: $1,150
Day 6: $900
Day 7: $1,234  ← Today

```

### Category Distribution

```text
Food:         40% ($493.82)  🟢 Green
Beverages:    30% ($370.37)  🔵 Blue
Desserts:     20% ($246.91)  🟠 Orange
Merchandise:  10% ($123.46)  🟣 Purple

```

### Payment Methods

```text
Card:      45% ($555.55)  🔵 Blue
Cash:      35% ($432.10)  🟢 Green
E-Wallet:  20% ($246.91)  🟣 Purple

```

### Top 5 Products

```text
1. Burger Combo      120 units  $1,440.00  ($12.00 each)
2. Iced Coffee       200 units  $  900.00  ($ 4.50 each)
3. Smoothie Bowl     130 units  $  845.00  ($ 6.50 each)
4. Pasta Special      60 units  $  840.00  ($14.00 each)
5. Chocolate Cake    110 units  $  715.00  ($ 6.50 each)

```

---

## ⚠️ Empty States

### No Data for Period

```text
┌─────────────────────────────────────┐
│                                     │
│           📊                        │
│                                     │
│    No sales data available          │
│    for the selected period          │
│                                     │
│    Try selecting a different        │
│    date range or generate           │
│    test data in Settings            │
│                                     │
└─────────────────────────────────────┘

```

### Loading State

```text
┌─────────────────────────────────────┐
│  ▓▓▓▓▓▓░░░░░░░░  Loading...         │
│                                     │
│  ┌────────┐ ┌────────┐             │
│  │░░░░░░░░│ │░░░░░░░░│  ← Skeleton │
│  │░░░░░░░░│ │░░░░░░░░│     loaders │
│  └────────┘ └────────┘             │
└─────────────────────────────────────┘

```

---

## 🎬 Animations

### Page Load

1. **Date selector** slides in from top (200ms)

2. **KPI cards** fade in sequentially (100ms delay each)

3. **Line chart** draws from left to right (500ms)

4. **Donut charts** grow from center (400ms)

5. **Product list** fades in (300ms)

### Date Change

1. **KPIs** pulse with new values (200ms)

2. **Charts** morph to new data (300ms)

3. **Product list** crossfades (250ms)

### Pull-to-Refresh Animation

1. **Pull down**: Circular indicator grows
2. **Release**: Spinner rotates
3. **Complete**: Check mark ✓, fade out (500ms)

---

## 🖱️ User Interactions

### Desktop (Mouse)

- **Hover KPI**: Subtle scale (1.02x), shadow increase

- **Hover Chart**: Tooltip appears with value

- **Click Date**: Chip selected, data updates

- **Scroll**: Smooth vertical scroll

### Mobile (Touch)

- **Tap KPI**: Ripple effect, no drill-down yet

- **Tap Chart**: Tooltip on touch point

- **Swipe Date**: Horizontal scroll chips

- **Pull Down**: Refresh gesture

### Keyboard (Desktop)

- **Tab**: Navigate through interactive elements

- **Enter**: Activate selected chip/button

- **Arrows**: Navigate date chips

- **Esc**: Close export bottom sheet

---

## 📱 Screen Sizes Tested

### Desktop

- **1920x1080**: 4-column KPIs, side-by-side charts

- **1366x768**: 4-column KPIs, side-by-side charts

- **1280x800** (iMin Swan 2): 4-column KPIs, optimized

### Tablet

- **1024x768**: 4-column KPIs, side-by-side charts

- **800x600**: 2-column KPIs, stacked charts

### Mobile

- **480x800**: 2-column KPIs, stacked charts

- **360x640**: 2-column KPIs, scrollable content

---

## ✨ Polish Details

### Shadows & Elevation

- **KPI Cards**: Elevation 2 (subtle shadow)

- **Charts**: Elevation 1 (minimal shadow)

- **Bottom Sheet**: Elevation 16 (strong shadow)

### Rounded Corners

- **Cards**: 12px radius

- **Chips**: 20px radius (pill shape)

- **Buttons**: 8px radius

- **Charts**: No border radius

### Typography

- **KPI Value**: 24sp, Bold (SF Pro Display)

- **KPI Title**: 14sp, Medium

- **Chart Title**: 16sp, Medium

- **Product Name**: 15sp, Medium

- **Chart Labels**: 12sp, Regular

### Spacing

- **Card Padding**: 16px all sides

- **Between Sections**: 24px

- **Chip Spacing**: 8px

- **List Item Spacing**: 12px

---

## 🎯 What Success Looks Like

### ✅ Perfect Implementation

- All 4 KPI cards show correct calculated values

- Line chart displays 7 data points smoothly

- Donut charts total to 100%

- Top products sorted by revenue

- Date changes update all components

- CSV export saves valid file

- Pull-to-refresh works smoothly

- No visual glitches or overlaps

- Responsive at all screen sizes

- Animations smooth (60 FPS)

### ❌ Issues to Watch For

- KPI values don't update on date change

- Charts show "No data" when data exists

- Export button doesn't respond

- Layout breaks on small screens

- Text overlaps or truncates incorrectly

- Slow animations (< 30 FPS)

- Memory usage spikes

- Crashes on large datasets

---

## 🎨 Brand Consistency

### FlutterPOS Style Guide

✅ Primary Color: #2563EB (Blue) - Used in selected chips, Net Sales KPI

✅ Success Color: #10B981 (Green) - Used in Gross Sales KPI

✅ Warning Color: #F97316 (Orange) - Used in Transactions KPI

✅ Info Color: #9333EA (Purple) - Used in Average Ticket KPI

✅ Text Primary: #1F2937 (Gray 900)
✅ Text Secondary: #6B7280 (Gray 600)
✅ Background: #F9FAFB (Gray 50)
✅ Surface: #FFFFFF (White)

---

**This is what you should see when you open the Modern Reports Dashboard!** 📊✨

If anything looks different, refer to the troubleshooting sections in the testing guides.
