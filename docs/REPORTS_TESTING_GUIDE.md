# Modern Reports Dashboard - Quick Testing Guide

## How to Access

### Method 1: From Mode Selection (Home Screen)

```text
Open FlutterPOS → FAB (Reports icon) → Modern Reports Dashboard

```

### Method 2: From Settings

```text
Open FlutterPOS → Settings (gear icon) → Reports → Modern Reports Dashboard

```

### Method 3: From Unified POS (Burger Menu)

```text
Open FlutterPOS → Unified POS → ☰ Menu → Reports → Modern Reports Dashboard

```

## What You'll See

### Top Section: Quick Date Selector

```text
┌──────────────────────────────────────────────────────────┐
│  Today  │ Yesterday │ This Week │ This Month │ Custom    │
└──────────────────────────────────────────────────────────┘

```

- Tap any chip to change date range

- "Custom" opens a date range picker

### KPI Cards (4 metrics in a grid)

```text
┌─────────────┬─────────────┐
│ 💰 $1,234   │ 📈 $1,100   │
│ Gross Sales │ Net Sales   │
└─────────────┴─────────────┘
┌─────────────┬─────────────┐
│ 🧾 45       │ 🛒 $27.42   │
│Transactions │ Avg Ticket  │
└─────────────┴─────────────┘

```

- Green: Gross Sales (total revenue)

- Blue: Net Sales (after tax & discounts)

- Orange: Transactions (order count)

- Purple: Average Ticket (per transaction)

### Sales Trend Chart (Line Chart)

```text
Sales Trend (Last 7 Days)
────────────────────────────
     │     ╱╲
     │   ╱    ╲    ╱╲
     │ ╱        ╲╱    ╲
     └──────────────────

```

- Shows last 7 days of sales

- Hover/tap for exact values

### Category & Payment Charts (Donut Charts)

```text
┌──────────────────────┬──────────────────────┐
│   Category Sales     │  Payment Methods     │
│       ┌───┐          │       ┌───┐          │
│      ╱     ╲         │      ╱     ╲         │
│     │   🍕  │        │     │  💳   │        │
│      ╲     ╱         │      ╲     ╱         │
│       └───┘          │       └───┘          │
└──────────────────────┴──────────────────────┘

```

- Left: Sales by category

- Right: Payment method breakdown

### Top Products List

```text
Top Products
───────────────────────────
1. Burger Combo    45 sold • $450.00
2. Iced Coffee     38 sold • $190.00
3. Caesar Salad    32 sold • $256.00

```

- Shows best-selling items

- Units sold + revenue per product

### Bottom: Export Options

```text
┌───────────────────────────────────────┐
│           📤 Export Report            │
└───────────────────────────────────────┘

```

- Tap to open export options:

  - CSV Export (✅ Working)

  - PDF Export (Coming soon)

  - Thermal Print (Coming soon)

## Testing Steps

### 1. Date Selection Test

- [ ] Tap "Today" - verify it shows today's sales

- [ ] Tap "Yesterday" - verify it shows yesterday's sales

- [ ] Tap "This Week" - verify it shows current week

- [ ] Tap "This Month" - verify it shows current month

- [ ] Tap "Custom" - select a custom date range, verify it updates

### 2. KPI Cards Test

- [ ] Verify Gross Sales shows a dollar amount

- [ ] Verify Net Sales is less than Gross Sales (if tax/discounts exist)

- [ ] Verify Transactions shows a number

- [ ] Verify Average Ticket = Gross Sales / Transactions

### 3. Charts Test

- [ ] Verify line chart shows 7 days of data

- [ ] Tap on a point in line chart - should show tooltip with value

- [ ] Verify category donut chart shows different colored segments

- [ ] Verify payment methods donut chart shows payment breakdown

### 4. Top Products Test

- [ ] Verify at least 3 products appear (if you have sales data)

- [ ] Check that units sold and revenue make sense

- [ ] Products should be sorted by sales (highest first)

### 5. Export Test

- [ ] Tap "Export Report" button

- [ ] Select "CSV Export"

- [ ] Choose where to save file

- [ ] Verify CSV file contains correct data

### 6. Pull-to-Refresh Test

- [ ] Swipe down from the top

- [ ] Verify loading indicator appears

- [ ] Verify data refreshes after loading

### 7. Responsive Test (if on desktop)

- [ ] Resize window to narrow width (< 600px)

- [ ] Verify KPI cards switch to 2-column layout

- [ ] Resize window to wide width (> 600px)

- [ ] Verify KPI cards switch to 4-column layout

## Expected Data Flow

```text
User Action               System Response
───────────────────────  ────────────────────
Select "Today"     →     KPIs update to show today's totals
                         Charts update to show today's data
                         Top products update to show today's best sellers

Select "This Week" →     KPIs show week-to-date totals
                         Line chart shows 7-day trend
                         Products show week's best sellers

Pull to refresh    →     All data reloads from database
                         Charts animate with new data
                         KPIs update with latest numbers

```

## Common Issues & Solutions

### Issue: No data appears

**Solution**:

- Check if you have any sales orders in the system

- Try selecting a different date range

- Use "Custom" to select a range you know has data

### Issue: Charts show "No data"

**Solution**:

- Ensure you have sales for the selected period

- Check if orders are in "completed" status (not "pending" or "cancelled")

### Issue: Export button doesn't work

**Solution**:

- CSV export should work - check file permissions

- PDF/Thermal show "Coming soon" toast (expected)

### Issue: KPI cards show $0.00

**Solution**:

- Verify you have completed orders in the selected date range

- Check that orders have non-zero totals

- Try selecting "All Time" or broader date range

## Performance Notes

- Dashboard should load in < 2 seconds with 100 orders

- Charts should animate smoothly (60 FPS)

- Pull-to-refresh should complete in < 1 second

## Device-Specific Notes

### iMin Swan 2 (Android Tablet)

- KPIs will show in 4-column layout (landscape)

- Charts will be large and easy to read

- Touch interactions should be responsive

### Desktop (Windows/Linux/macOS)

- Window is resizable

- Mouse hover shows chart tooltips

- Keyboard shortcuts: Ctrl+R to refresh

## Next Steps After Testing

1. Report any bugs or visual issues
2. Suggest improvements to date selector
3. Request additional KPIs or charts
4. Test with real sales data (not mock data)
