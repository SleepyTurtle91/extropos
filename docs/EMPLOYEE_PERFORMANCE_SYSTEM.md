# Employee Performance System

## Overview

The Employee Performance System provides comprehensive analytics for tracking staff productivity, sales performance, commissions, and shift reports in FlutterPOS. Accessible to managers and administrators, this feature enables data-driven employee management and incentive programs.

**Version**: 1.0.14  
**Release Date**: November 26, 2025  
**Access Level**: Admin, Manager

---

## Features

### 1. Performance Overview

- **Employee Summary**: View all employees' performance metrics in one place

- **Summary Cards**:

  - Total Sales (all employees combined)

  - Total Orders processed

  - Total Commissions earned

  - Average sales per employee

- **Performance Table**: Detailed breakdown with:

  - Employee name and role

  - Total sales amount

  - Number of orders

  - Items sold count

  - Average order value

  - Commission earned

- **Commission Tiers**: Visual breakdown of tier distribution

### 2. Leaderboard

- **Rankings**: Top 10 employees by sales performance

- **Visual Badges**:

  - 🥇 Gold (1st place)

  - 🥈 Silver (2nd place)

  - 🥉 Bronze (3rd place)

  - Numbered badges (4th-10th)

- **Stats Display**: Orders count and commission for each employee

- **Sorting**: Automatically sorted by total sales (highest to lowest)

### 3. Shift Reports

- **Employee Selection**: Choose any active employee

- **Shift Summary**:

  - Shift start and end times

  - Total duration

  - Total sales

  - Number of orders

  - Items sold

  - Average order value

- **Payment Breakdown**:

  - Cash sales (percentage and amount)

  - Card sales (percentage and amount)

  - Other payment methods (percentage and amount)

- **Refunds & Voids**: Track cancelled transactions and refunds processed

---

## Commission System

### Tier Structure

FlutterPOS uses a 4-tier commission system based on total sales:

| Tier | Sales Range | Commission Rate | Badge Color |
|------|-------------|-----------------|-------------|
| **Bronze** | RM 0 - RM 999 | 2% | Brown |

| **Silver** | RM 1,000 - RM 4,999 | 3% | Grey |

| **Gold** | RM 5,000 - RM 9,999 | 5% | Amber |

| **Platinum** | RM 10,000+ | 7% | Purple |

### Commission Calculation

Commissions are calculated based on the employee's **total sales** within the selected date range:

```text
Example 1 (Bronze Tier):

- Total Sales: RM 500

- Commission Rate: 2%

- Commission: RM 500 × 0.02 = RM 10.00

Example 2 (Gold Tier):

- Total Sales: RM 7,500

- Commission Rate: 5%

- Commission: RM 7,500 × 0.05 = RM 375.00

Example 3 (Platinum Tier):

- Total Sales: RM 15,000

- Commission Rate: 7%

- Commission: RM 15,000 × 0.07 = RM 1,050.00

```text

**Notes**:


- Commissions are calculated on **completed sales only**

- Cancelled and voided orders are excluded

- Refunded orders are excluded from commission calculations

- Each sale is attributed to the employee who processed the order (stored in `orders.user_id`)

---


## How to Use



### Access the Feature


1. Open **Settings** from the main menu

2. Scroll to **Reports** section

3. Tap **Employee Performance**


### Select Date Range


1. Tap the **calendar icon** in the top-right corner

2. Choose start and end dates
3. The system defaults to **last 7 days**
4. Tap **OK** to apply the date range


### View Performance Overview


**Summary Cards** at the top show:


- Combined totals for all employees

- Average performance per employee

**Performance Table** below shows:


- Individual employee metrics

- Sortable by any column

- Scroll horizontally for all data

**Commission Breakdown** displays:


- All four tiers with their criteria

- Number of employees in each tier

- Visual tier badges with colors


### Check Leaderboard


1. Switch to **Leaderboard** tab

2. View top 10 employees ranked by sales
3. See visual rank badges (1st = gold trophy, 2nd = silver trophy, 3rd = bronze trophy)
4. Check individual stats for each ranking


### Generate Shift Report


1. Switch to **Shift Reports** tab

2. Select an employee from the left panel
3. View detailed shift statistics:

   - Sales summary

   - Payment method breakdown

   - Refunds and voids (if any)

4. Shift duration is calculated automatically from date range


### Export Data


1. Tap the **download icon** in the top-right corner

2. CSV file is generated with all performance data
3. File includes:

   - Report metadata (business name, date range, currency)

   - All employee performance metrics

   - Commission tiers for each employee

4. **File Location**:

   - **Android/iOS**: `Downloads` folder

   - **Desktop**: System downloads directory

---


## Technical Details



### Database Integration


The system queries the following tables:


- `users`: Employee information (name, role, status)

- `orders`: Sales transactions with user_id foreign key

- `order_items`: Individual items in each order

- `payment_methods`: Payment type classification


### SQL Queries


**Performance Summary**:

```sql
SELECT 
  u.id, u.name, u.role,
  SUM(o.total) as total_sales,
  COUNT(o.id) as order_count,
  SUM(oi.quantity) as items_sold,
  AVG(o.total) as average_order_value
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
  AND o.status NOT IN ('cancelled', 'voided')
LEFT JOIN order_items oi ON o.id = oi.order_id
WHERE u.is_active = 1
GROUP BY u.id
ORDER BY total_sales DESC
```text

**Hourly Breakdown**:

```sql
SELECT 
  CAST(strftime('%H', created_at) AS INTEGER) as hour,
  SUM(total) as revenue,
  COUNT(*) as order_count
FROM orders
WHERE user_id = ? 
  AND created_at >= ? 
  AND created_at <= ?
  AND status NOT IN ('cancelled', 'voided')
GROUP BY hour
```text


### Data Models


**EmployeePerformance**:


- userId, userName, userRole

- totalSales, orderCount, itemsSold

- averageOrderValue, commission

- startDate, endDate

**EmployeeRanking**:


- rank (1-10)

- userId, userName, userRole

- totalSales, orderCount, commission

**ShiftReport**:


- userId, userName

- shiftStart, shiftEnd, shiftDuration

- totalSales, orderCount, itemsSold

- cashSales, cardSales, otherSales

- refundCount, refundAmount, voidCount

- averageOrderValue

**CommissionTier**:


- minSales, maxSales, rate, tierName

- `calculateCommission(sales)` method

- `appliesTo(sales)` validation

---


## User Permissions


| Role | View Performance | View Leaderboard | View Shift Reports | Export CSV |
|------|------------------|------------------|-------------------|------------|
| **Admin** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |

| **Manager** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |

| **Cashier** | ❌ No | ❌ No | ❌ No | ❌ No |

| **Waiter** | ❌ No | ❌ No | ❌ No | ❌ No |

Access control is enforced through the Settings menu, which is only accessible to Admin and Manager roles.

---


## CSV Export Format



### Metadata Section


```csv
meta_key,meta_value
report_type,Employee Performance Report
generated_at,2025-11-26 15:30:00
business_name,Your Business Name
period_start,2025-11-19 00:00:00
period_end,2025-11-26 23:59:59
currency,RM
```text


### Data Section


```csv
Employee Name,Role,Total Sales,Orders,Items Sold,Avg Order Value,Commission,Commission Tier
John Doe,admin,15000.00,120,450,125.00,1050.00,Platinum
Jane Smith,cashier,7500.00,85,320,88.24,375.00,Gold
Bob Lee,waiter,800.00,25,90,32.00,16.00,Bronze
```text

---


## Best Practices



### For Managers


1. **Regular Reviews**: Check performance weekly to identify trends
2. **Set Targets**: Use tier thresholds as sales goals
3. **Fair Comparison**: Always compare employees with same roles
4. **Shift Scheduling**: Use shift reports to optimize staffing
5. **Incentivize**: Share leaderboard with team to motivate performance


### For Administrators


1. **Data Export**: Export monthly reports for payroll processing
2. **Trend Analysis**: Compare period-over-period to track growth
3. **Commission Audits**: Verify commission calculations before payouts
4. **Role-Based Analysis**: Filter by role to ensure fair comparisons
5. **Performance Reviews**: Use data in employee evaluations


### Date Range Selection


- **Daily**: Compare day-to-day performance

- **Weekly**: Standard performance tracking (default)

- **Monthly**: Comprehensive commission calculations

- **Custom**: Specific campaigns or events

---


## Troubleshooting



### No Data Showing


**Problem**: Performance data is empty  
**Solutions**:


- Check if selected date range has any orders

- Verify employees have processed orders (orders.user_id is set)

- Ensure orders are not all cancelled/voided

- Confirm users are marked as active (is_active = 1)


### Incorrect Commission Amounts


**Problem**: Commission doesn't match expected value  
**Solutions**:


- Verify sales amount is within expected tier

- Check that cancelled/voided orders are excluded

- Ensure refunded orders are not counted

- Recalculate using tier rate (sales × rate)


### Missing Employees in List


**Problem**: Some employees don't appear  
**Solutions**:


- Check if user status is Active (not Inactive or Suspended)

- Verify user has processed at least one order in date range

- Confirm user_id is correctly set on orders


### CSV Export Failed


**Problem**: Cannot save CSV file  
**Solutions**:


- Check storage permissions on mobile devices

- Ensure sufficient disk space

- Verify downloads directory exists and is writable

- Try exporting smaller date range

---


## Future Enhancements


Potential features for future versions:

1. **Custom Commission Tiers**: Allow admins to define their own tiers and rates
2. **Hourly Heatmaps**: Visual chart of peak performance hours
3. **Goal Setting**: Set and track individual sales targets
4. **Performance Alerts**: Notifications for milestone achievements
5. **Comparative Analytics**: Side-by-side employee comparisons
6. **Historical Trends**: Multi-period trend charts
7. **Category Performance**: Track performance by product category
8. **Team Performance**: Group employees into teams for competition
9. **Attendance Tracking**: Integrate with shift clock-in/out
10. **Bonus Calculations**: Automated bonus calculations based on targets

---


## Related Features


- **Sales History**: View individual transactions by employee

- **Advanced Reports**: Overall business analytics

- **Analytics Dashboard**: Real-time sales charts

- **Users Management**: Add/edit employee accounts

---


## Support


For questions or issues with the Employee Performance system:

1. Check this documentation for common solutions
2. Verify database integrity (Settings → Developer Tools → Database Test)
3. Export CSV to verify data is being tracked correctly
4. Contact system administrator for access issues

---

**Last Updated**: November 26, 2025  
**Version**: 1.0.14  
**Documentation**: EMPLOYEE_PERFORMANCE_SYSTEM.md
