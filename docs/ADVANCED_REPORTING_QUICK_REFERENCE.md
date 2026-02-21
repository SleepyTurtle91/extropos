# Advanced Reporting - Quick Reference Guide

## 📖 Overview

This guide provides quick instructions for using FlutterPOS's advanced reporting features, including scheduled reports, comparative analysis, forecasting, and ABC inventory analysis.

---

## 🗓️ Scheduled Reports

### Creating a Scheduled Report

1. Navigate to **Reports** → **Advanced Reports** → **Scheduled Reports**

2. Click the **"New Schedule"** floating action button

3. Fill in the form:

   - **Schedule Name**: Descriptive name (e.g., "Daily Sales Summary")

   - **Report Type**: Select from dropdown (Sales Summary, Product Sales, etc.)

   - **Frequency**: Choose execution interval

     - Hourly: Every 60 minutes

     - Daily: 8:00 AM every day

     - Weekly: Same day/time every week

     - Monthly: 1st of each month at 8:00 AM

     - Quarterly: 1st of Jan/Apr/Jul/Oct at 8:00 AM

     - Yearly: January 1st at 8:00 AM

   - **Recipient Emails**: Comma-separated email addresses

   - **Export Formats**: Select one or more (PDF, CSV, Excel, JSON)

4. Click **"Save"**

### Managing Scheduled Reports

**View All Schedules**:

- Grid view (desktop): Shows up to 4 schedules per row

- List view (mobile): Shows one schedule per row

**Schedule Card Information**:

- Report name and type

- Frequency

- Number of recipients

- Export formats

- Next scheduled run time

- Last execution time

**Available Actions**:

- **Toggle Active/Inactive**: Use the switch to pause/resume

- **Test Run**: Generate report immediately without scheduling

- **Edit**: Modify schedule configuration

- **Delete**: Remove schedule permanently (with confirmation)

### Schedule Status Indicators

| Status | Meaning |
|--------|---------|
| Green toggle ON | Schedule is active |
| Gray toggle OFF | Schedule is paused |
| Next Run: Today | Will execute within 24 hours |
| Last Run: 2m ago | Last executed 2 minutes ago |

---

## 📊 Comparative Analysis

### Generating a Comparison

1. Navigate to **Reports** → **Advanced Reports** → **Comparative Analysis**

2. Click the **"Change Periods"** icon (tune icon) in the app bar

3. Select periods:

   - **Current Period**: Choose from presets (Today, This Week, This Month, etc.)

   - **Comparison Period**: Choose what to compare against (Yesterday, Last Week, Last Month, etc.)

4. Click **"Apply"**
5. View the comparison dashboard

### Understanding the Dashboard

**Period Header**:

- Shows both periods being compared

- Color-coded: Current (blue), Comparison (gray)

**Metrics Overview Cards**:

- **Large Number**: Current period value

- **vs Value**: Comparison period value

- **Percentage Badge**: Change percentage

  - Green + up arrow: Improvement

  - Red + down arrow: Decline

  - No change: Stable

**Detailed Comparison Table** (Desktop):

- Sortable columns

- All metrics in one view

- Trend indicators

**Detailed Comparison List** (Mobile):

- Scrollable list

- Summary per metric

- Change percentages

### Available Metrics

- **Gross Sales**: Total sales before discounts/refunds

- **Net Sales**: Sales after discounts and refunds

- **Transactions**: Number of completed sales

- **Average Transaction**: Average sale value

### Preset Periods

| Preset | Date Range |
|--------|-----------|
| Today | Current day (00:00 - 23:59) |

| Yesterday | Previous day |
| This Week | Monday - Sunday (current week) |

| Last Week | Monday - Sunday (previous week) |

| This Month | 1st - last day (current month) |

| Last Month | 1st - last day (previous month) |

| This Year | Jan 1 - Dec 31 (current year) |

| Last Year | Jan 1 - Dec 31 (previous year) |

---

## 🔮 Sales Forecasting

### Generating a Forecast

1. Navigate to **Reports** → **Advanced Reports** → **Sales Forecast**

2. Select forecast parameters:

   - **Forecast Period**: Number of days to forecast (7, 14, 30)

   - **Forecast Method**:

     - Linear: Simple trend-based

     - Exponential: Weighted average

     - Seasonal: Day-of-week patterns

3. Click **"Generate Forecast"**

### Forecast Methods Explained

**Linear Regression**:

- Best for: Steady growth/decline trends

- Requires: 30+ days historical data

- Accuracy: ±15% confidence interval

- Formula: Future sales = Average + (Trend × Days)

**Exponential Smoothing**:

- Best for: Recent data is more important

- Smoothing factor (alpha): 0.3

- Accuracy: ±15% confidence interval

- Adapts quickly to changes

**Seasonal Pattern**:

- Best for: Repeating weekly patterns

- Calculates: Average per day of week

- Accuracy: ±15% confidence interval

- Example: Higher sales on Fri/Sat

### Reading the Forecast Chart

- **Solid Blue Line**: Historical actual sales

- **Dashed Blue Line**: Forecasted sales

- **Shaded Blue Area**: Confidence interval (upper/lower bounds)

- **Vertical Line**: Divides historical vs forecast

### Forecast Accuracy

**MAPE (Mean Absolute Percentage Error)**:

- < 10%: Excellent

- 10-15%: Good

- 15-20%: Fair

- > 20%: Poor (consider different method)

**Improving Accuracy**:

1. Use more historical data (60+ days recommended)

2. Choose appropriate method for your pattern
3. Exclude outliers (holidays, special events)
4. Update forecast weekly

---

## 📦 ABC Analysis (Inventory Optimization)

### Running ABC Analysis

1. Navigate to **Reports** → **Advanced Reports** → **ABC Analysis**

2. Select time period (default: last 30 days)
3. Click **"Generate Analysis"**

### Understanding ABC Categories

**Category A (High Value)**:

- **Revenue Share**: ~80% of total revenue

- **Item Count**: ~20% of total items

- **Priority**: High - Monitor closely

- **Action**: Maintain optimal stock levels

- **Reorder Frequency**: Weekly or more

- **Stock-out Risk**: Critical - avoid at all costs

**Category B (Medium Value)**:

- **Revenue Share**: ~15% of total revenue

- **Item Count**: ~30% of total items

- **Priority**: Medium - Regular reviews

- **Action**: Moderate inventory levels

- **Reorder Frequency**: Bi-weekly or monthly

- **Stock-out Risk**: Moderate - acceptable delays

**Category C (Low Value)**:

- **Revenue Share**: ~5% of total revenue

- **Item Count**: ~50% of total items

- **Priority**: Low - Minimize stock

- **Action**: Consider discontinuation

- **Reorder Frequency**: Quarterly or on-demand

- **Stock-out Risk**: Low - acceptable out-of-stock

### ABC Analysis Chart

**Pareto Chart**:

- **Blue Bars**: Individual item revenue

- **Red Line**: Cumulative percentage

- **Green Zone**: Category A items

- **Yellow Zone**: Category B items

- **Red Zone**: Category C items

### Action Recommendations

**Category A Items**:
✅ Never allow stock-outs
✅ Negotiate better pricing (bulk discounts)
✅ Monitor demand patterns closely
✅ Consider safety stock levels
✅ Track daily/weekly

**Category B Items**:
⚠️ Regular stock reviews (weekly/monthly)
⚠️ Moderate safety stock
⚠️ Reorder when stock reaches 25%
⚠️ Track weekly/monthly

**Category C Items**:
❌ Minimize holding costs
❌ Consider drop-shipping
❌ Order only when needed
❌ Evaluate discontinuation
❌ Track monthly/quarterly

### Interpreting Results

**Example Output**:

```text
Category A: 15 items (20%) = RM 80,000 (80% revenue)
Category B: 25 items (33%) = RM 15,000 (15% revenue)
Category C: 35 items (47%) = RM 5,000 (5% revenue)

```text

**What to Look For**:


- Items moving between categories (upgrade/downgrade)

- Over-stocked C items (reduce inventory)

- Under-stocked A items (increase stock)

- New products entering A category (growth opportunities)

---


## 🛠️ Custom Report Builder



### Creating a Custom Report


1. Navigate to **Reports** → **Advanced Reports** → **Custom Reports**

2. Click **"New Custom Report"**
3. Configure report:

   - **Name**: Report name

   - **Description**: Purpose and usage notes

   - **Select Metrics**: Choose data to display

   - **Group By**: Time intervals (hourly/daily/weekly/monthly)

   - **Filters**: Conditions to filter data

   - **Sorting**: Order results


### Available Metrics


**Sales Metrics**:


- Total Sales

- Net Sales

- Gross Profit

- Average Transaction Value

- Transaction Count

**Product Metrics**:


- Units Sold

- Revenue per Product

- Product Profit Margin

- Stock Levels

**Customer Metrics**:


- New Customers

- Repeat Customers

- Customer Lifetime Value

**Employee Metrics**:


- Sales per Employee

- Transactions per Employee

- Average Sale per Employee


### Aggregation Types


| Type | Description | Example |
|------|-------------|---------|
| Sum | Total of all values | Total sales |
| Average | Mean value | Average transaction |
| Count | Number of records | Transaction count |
| Min | Lowest value | Smallest sale |
| Max | Highest value | Largest sale |
| Median | Middle value | Median sale |


### Filter Operators


| Operator | Usage | Example |
|----------|-------|---------|
| Equals | Exact match | Category = "Electronics" |
| Not Equals | Exclude match | Status ≠ "Cancelled" |
| Greater Than | Value above | Amount > 100 |
| Less Than | Value below | Amount < 50 |
| Between | Range | Date between Jan 1 - Jan 31 |

| Contains | Partial match | Name contains "Phone" |
| Starts With | Prefix match | SKU starts with "PROD-" |
| In List | Multiple values | Category in [Electronics, Clothing] |


### Grouping Intervals


| Interval | Groups By | Use Case |
|----------|-----------|----------|
| Hourly | Each hour (0-23) | Intraday patterns |
| Daily | Each day | Daily trends |
| Weekly | Each week (Mon-Sun) | Weekly patterns |
| Monthly | Each month (Jan-Dec) | Monthly comparisons |
| Quarterly | Each quarter (Q1-Q4) | Seasonal analysis |
| Yearly | Each year | Year-over-year |

---


## 📧 Email Delivery



### Configuring Email Settings


1. Navigate to **Settings** → **Business Information** → **Email Configuration**

2. Enter SMTP details:

   - **SMTP Host**: mail.example.com

   - **SMTP Port**: 587 (TLS) or 465 (SSL)

   - **Username**: <your-email@example.com>

   - **Password**: Your email password

   - **Use TLS**: Enable for secure connection

3. Click **"Test Connection"** to verify

4. Click **"Save"**


### Email Formats


**PDF**:


- Professional formatted report

- Includes company logo and branding

- Tables and charts

- Suitable for: Management, clients

**CSV**:


- Raw data export

- Opens in Excel/Google Sheets

- Easy to manipulate

- Suitable for: Data analysis, import to other systems

**Excel**:


- Formatted spreadsheet

- Multiple sheets (summary + details)

- Formulas included

- Suitable for: Financial analysis, presentations

**JSON**:


- Machine-readable format

- Programmatic access

- API integration

- Suitable for: Developers, system integration

---


## 🔄 Background Scheduler



### How It Works


1. **Check Interval**: Every 5 minutes
2. **Query**: Get all active schedules with `next_run <= now`
3. **Execute**: Generate report
4. **Email**: Send to recipients with attachments
5. **Update**: Set `last_run = now`, calculate `next_run`
6. **Log**: Save execution history


### Execution Status


| Status | Meaning | Action |
|--------|---------|--------|
| Success | Report generated and sent | None required |
| Failed | Generation error | Check logs, retry manually |
| Partial | Generated but email failed | Check email settings |


### Troubleshooting


**Schedule Not Running**:

1. Check if schedule is active (toggle ON)
2. Verify `next_run` time is in the past
3. Check background service is running
4. Review execution history for errors

**Email Not Sending**:

1. Test SMTP connection in settings
2. Verify recipient email addresses
3. Check spam/junk folders
4. Review execution history for error message

**Incorrect Next Run Time**:

1. Verify frequency setting
2. Check system timezone
3. Manually edit next_run if needed
4. Contact support if issue persists

---


## 📱 Mobile vs Desktop Differences



### Desktop (Width ≥ 1200px)


- Grid view: 4 columns

- DataTable for comparisons

- Side-by-side period cards

- More metrics visible at once


### Tablet (900px - 1199px)


- Grid view: 2-3 columns

- DataTable or responsive list

- Stacked period cards

- Scrollable metrics


### Mobile (Width < 900px)


- List view: 1 column

- List for comparisons

- Vertical period cards

- Swipeable metrics

---


## 🎯 Best Practices



### Scheduled Reports


- ✅ Name schedules descriptively (include frequency)

- ✅ Test run before activating schedule

- ✅ Start with weekly frequency, adjust as needed

- ✅ Include multiple recipients for redundancy

- ✅ Export to both PDF (viewing) and CSV (analysis)

- ❌ Don't schedule hourly reports unless necessary

- ❌ Don't use personal emails for business reports


### Comparative Analysis


- ✅ Compare similar time periods (week vs week, month vs month)

- ✅ Look for trends over multiple comparisons

- ✅ Investigate large percentage changes (>20%)

- ✅ Use year-over-year for seasonal businesses

- ❌ Don't compare different day counts (30 days vs 7 days)

- ❌ Don't ignore small consistent declines


### Forecasting


- ✅ Use 30+ days of historical data

- ✅ Choose method matching your business pattern

- ✅ Update forecasts weekly

- ✅ Exclude outliers (holidays, events)

- ✅ Track actual vs forecast accuracy

- ❌ Don't rely on forecasts during unusual times

- ❌ Don't use linear for seasonal businesses


### ABC Analysis


- ✅ Run monthly to track changes

- ✅ Focus inventory efforts on A items

- ✅ Consider discontinuing slow-moving C items

- ✅ Negotiate better pricing for A items

- ❌ Don't stock out on A items

- ❌ Don't over-invest in C item inventory

---


## 🆘 Common Issues



### "No data available"


**Cause**: Selected period has no sales
**Solution**: Choose a different time period


### "Forecast accuracy low (>20%)"


**Cause**: Insufficient historical data or wrong method
**Solution**: Use more historical data or try different method


### "Email sending failed"


**Cause**: SMTP configuration incorrect
**Solution**: Verify settings, test connection


### "Schedule not executing"


**Cause**: Background service not running
**Solution**: Restart app, check background permissions


### "Report taking too long"


**Cause**: Large dataset or complex calculations
**Solution**: Reduce date range, add filters

---


## 📞 Support


**Documentation**: `/docs/ADVANCED_REPORTING_IMPLEMENTATION_SUMMARY.md`
**Database Schema**: `/docs/ADVANCED_REPORTING_DATABASE_SCHEMA.md`
**Issues**: Create GitHub issue with logs and screenshots
**Email**: <support@extrotarget.com>

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-25  
**Platform**: FlutterPOS v1.0.14+
