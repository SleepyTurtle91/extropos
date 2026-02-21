# Advanced Reporting Database Schema

This document describes the database schema additions for the advanced reporting features.

## New Tables

### scheduled_reports

Stores automated report schedule configurations.

```sql
CREATE TABLE scheduled_reports (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  report_type TEXT NOT NULL,
  period_type TEXT,
  period_start TEXT,
  period_end TEXT,
  period_label TEXT,
  frequency TEXT NOT NULL,
  recipient_emails TEXT NOT NULL,
  export_formats TEXT NOT NULL,
  custom_filters TEXT,
  is_active INTEGER DEFAULT 1,
  next_run TEXT,
  last_run TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT
);
```text

**Columns:**


- `id`: Unique identifier (UUID)

- `name`: User-defined schedule name

- `report_type`: Enum value from ReportType (salesSummary, productSales, etc.)

- `period_type`: Static period type or null for dynamic periods

- `period_start`: ISO 8601 date string for custom periods

- `period_end`: ISO 8601 date string for custom periods

- `period_label`: Human-readable period description

- `frequency`: Enum value from ScheduleFrequency (hourly, daily, weekly, monthly, quarterly, yearly)

- `recipient_emails`: JSON array of email addresses

- `export_formats`: JSON array of ExportFormat enum values (csv, pdf, excel, json)

- `custom_filters`: JSON object with report-specific filters (optional)

- `is_active`: 1 = active, 0 = inactive

- `next_run`: ISO 8601 datetime string for next scheduled execution

- `last_run`: ISO 8601 datetime string for last execution (null if never run)

- `created_at`: ISO 8601 datetime string of creation

- `updated_at`: ISO 8601 datetime string of last modification

**Indexes:**

```sql
CREATE INDEX idx_scheduled_reports_next_run ON scheduled_reports(next_run);
CREATE INDEX idx_scheduled_reports_is_active ON scheduled_reports(is_active);
```text


### report_execution_history


Tracks execution history of scheduled reports.

```sql
CREATE TABLE report_execution_history (
  id TEXT PRIMARY KEY,
  scheduled_report_id TEXT NOT NULL,
  executed_at TEXT NOT NULL,
  status TEXT NOT NULL,
  error_message TEXT,
  report_data TEXT,
  export_paths TEXT,
  execution_time_ms INTEGER,
  FOREIGN KEY (scheduled_report_id) REFERENCES scheduled_reports(id) ON DELETE CASCADE
);
```text

**Columns:**


- `id`: Unique identifier (UUID)

- `scheduled_report_id`: Foreign key to scheduled_reports.id

- `executed_at`: ISO 8601 datetime string of execution

- `status`: success, failed, partial

- `error_message`: Error details if status = failed

- `report_data`: JSON snapshot of generated report (optional, for debugging)

- `export_paths`: JSON array of file paths where exports were saved

- `execution_time_ms`: Execution duration in milliseconds

**Indexes:**

```sql
CREATE INDEX idx_execution_history_scheduled_report ON report_execution_history(scheduled_report_id);
CREATE INDEX idx_execution_history_executed_at ON report_execution_history(executed_at);
```text


### forecast_models


Stores forecast model parameters and accuracy metrics.

```sql
CREATE TABLE forecast_models (
  id TEXT PRIMARY KEY,
  model_type TEXT NOT NULL,
  parameters TEXT NOT NULL,
  accuracy REAL,
  generated_at TEXT NOT NULL,
  forecast_start TEXT NOT NULL,
  forecast_end TEXT NOT NULL,
  historical_period_start TEXT NOT NULL,
  historical_period_end TEXT NOT NULL,
  confidence_interval REAL,
  is_active INTEGER DEFAULT 1
);
```text

**Columns:**


- `id`: Unique identifier (UUID)

- `model_type`: linear, exponential, seasonal

- `parameters`: JSON object with model-specific parameters (slope, intercept, alpha, seasonality factors)

- `accuracy`: MAPE (Mean Absolute Percentage Error) as decimal (e.g., 0.15 = 15%)

- `generated_at`: ISO 8601 datetime string

- `forecast_start`: ISO 8601 date string for forecast start

- `forecast_end`: ISO 8601 date string for forecast end

- `historical_period_start`: ISO 8601 date string for training data start

- `historical_period_end`: ISO 8601 date string for training data end

- `confidence_interval`: Confidence range as percentage (e.g., 15.0 = ±15%)

- `is_active`: 1 = current model, 0 = archived

**Indexes:**

```sql
CREATE INDEX idx_forecast_models_generated_at ON forecast_models(generated_at);
```text


### custom_report_templates


Stores user-defined custom report configurations.

```sql
CREATE TABLE custom_report_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  selected_metrics TEXT NOT NULL,
  group_by_fields TEXT,
  filters TEXT,
  sorting TEXT,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  is_shared INTEGER DEFAULT 0
);
```text

**Columns:**


- `id`: Unique identifier (UUID)

- `name`: Template name

- `description`: Template description (optional)

- `selected_metrics`: JSON array of ReportMetric objects

- `group_by_fields`: JSON array of ReportGroupBy objects (optional)

- `filters`: JSON array of ReportFilter objects (optional)

- `sorting`: JSON array of ReportSort objects (optional)

- `created_by`: User ID who created the template

- `created_at`: ISO 8601 datetime string

- `updated_at`: ISO 8601 datetime string

- `is_shared`: 1 = shared with all users, 0 = private to creator

**Indexes:**

```sql
CREATE INDEX idx_custom_templates_created_by ON custom_report_templates(created_by);
CREATE INDEX idx_custom_templates_is_shared ON custom_report_templates(is_shared);
```text


## Migration SQL


Run this migration to add all advanced reporting tables:

```sql
-- Create scheduled_reports table

CREATE TABLE IF NOT EXISTS scheduled_reports (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  report_type TEXT NOT NULL,
  period_type TEXT,
  period_start TEXT,
  period_end TEXT,
  period_label TEXT,
  frequency TEXT NOT NULL,
  recipient_emails TEXT NOT NULL,
  export_formats TEXT NOT NULL,
  custom_filters TEXT,
  is_active INTEGER DEFAULT 1,
  next_run TEXT,
  last_run TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_scheduled_reports_next_run ON scheduled_reports(next_run);
CREATE INDEX IF NOT EXISTS idx_scheduled_reports_is_active ON scheduled_reports(is_active);

-- Create report_execution_history table

CREATE TABLE IF NOT EXISTS report_execution_history (
  id TEXT PRIMARY KEY,
  scheduled_report_id TEXT NOT NULL,
  executed_at TEXT NOT NULL,
  status TEXT NOT NULL,
  error_message TEXT,
  report_data TEXT,
  export_paths TEXT,
  execution_time_ms INTEGER,
  FOREIGN KEY (scheduled_report_id) REFERENCES scheduled_reports(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_execution_history_scheduled_report ON report_execution_history(scheduled_report_id);
CREATE INDEX IF NOT EXISTS idx_execution_history_executed_at ON report_execution_history(executed_at);

-- Create forecast_models table

CREATE TABLE IF NOT EXISTS forecast_models (
  id TEXT PRIMARY KEY,
  model_type TEXT NOT NULL,
  parameters TEXT NOT NULL,
  accuracy REAL,
  generated_at TEXT NOT NULL,
  forecast_start TEXT NOT NULL,
  forecast_end TEXT NOT NULL,
  historical_period_start TEXT NOT NULL,
  historical_period_end TEXT NOT NULL,
  confidence_interval REAL,
  is_active INTEGER DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_forecast_models_generated_at ON forecast_models(generated_at);

-- Create custom_report_templates table

CREATE TABLE IF NOT EXISTS custom_report_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  selected_metrics TEXT NOT NULL,
  group_by_fields TEXT,
  filters TEXT,
  sorting TEXT,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  is_shared INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_custom_templates_created_by ON custom_report_templates(created_by);
CREATE INDEX IF NOT EXISTS idx_custom_templates_is_shared ON custom_report_templates(is_shared);
```text


## DatabaseService Method Additions


Add these methods to `lib/services/database_service.dart`:


### Scheduled Reports


```dart
// Save scheduled report
Future<void> saveScheduledReport(ScheduledReport report);

// Get all scheduled reports
Future<List<ScheduledReport>> getScheduledReports({bool activeOnly = false});

// Get scheduled report by ID
Future<ScheduledReport?> getScheduledReportById(String id);

// Update scheduled report
Future<void> updateScheduledReport(ScheduledReport report);

// Delete scheduled report
Future<void> deleteScheduledReport(String id);

// Get reports due for execution
Future<List<ScheduledReport>> getReportsDueForExecution();
```text


### Execution History


```dart
// Save execution history
Future<void> saveExecutionHistory(ReportExecutionHistory history);

// Get execution history for a scheduled report
Future<List<ReportExecutionHistory>> getExecutionHistory(String scheduledReportId, {int limit = 10});

// Get recent execution history
Future<List<ReportExecutionHistory>> getRecentExecutions({int limit = 20});
```text


### Forecast Models


```dart
// Save forecast model
Future<void> saveForecastModel(ForecastModel model);

// Get active forecast model
Future<ForecastModel?> getActiveForecastModel();

// Get forecast model history
Future<List<ForecastModel>> getForecastModelHistory({int limit = 10});
```text


### Custom Report Templates


```dart
// Save custom template
Future<void> saveCustomReportTemplate(CustomReportTemplate template);

// Get user's custom templates
Future<List<CustomReportTemplate>> getUserCustomTemplates(String userId);

// Get shared custom templates
Future<List<CustomReportTemplate>> getSharedCustomTemplates();

// Delete custom template
Future<void> deleteCustomReportTemplate(String id);
```text


## Example Data



### Sample Scheduled Report


```json
{
  "id": "abc123-def456",
  "name": "Daily Sales Summary",
  "report_type": "salesSummary",
  "period_type": "today",
  "frequency": "daily",
  "recipient_emails": ["manager@example.com", "owner@example.com"],
  "export_formats": ["pdf", "csv"],
  "custom_filters": null,
  "is_active": 1,
  "next_run": "2025-01-26T08:00:00Z",
  "last_run": "2025-01-25T08:00:00Z",
  "created_at": "2025-01-20T10:00:00Z",
  "updated_at": "2025-01-25T08:00:05Z"
}
```text


### Sample Execution History


```json
{
  "id": "exec-789",
  "scheduled_report_id": "abc123-def456",
  "executed_at": "2025-01-25T08:00:03Z",
  "status": "success",
  "error_message": null,
  "report_data": null,
  "export_paths": ["/exports/daily_sales_2025-01-25.pdf", "/exports/daily_sales_2025-01-25.csv"],
  "execution_time_ms": 3247
}
```text


### Sample Forecast Model


```json
{
  "id": "forecast-123",
  "model_type": "seasonal",
  "parameters": {
    "seasonality_period": 7,
    "day_weights": {
      "1": 0.95,
      "2": 0.87,
      "3": 0.89,
      "4": 0.91,
      "5": 1.15,
      "6": 1.23,
      "7": 1.00
    },
    "base_average": 2450.75
  },
  "accuracy": 0.12,
  "generated_at": "2025-01-25T10:00:00Z",
  "forecast_start": "2025-01-26",
  "forecast_end": "2025-02-02",
  "historical_period_start": "2024-12-26",
  "historical_period_end": "2025-01-25",
  "confidence_interval": 15.0,
  "is_active": 1
}
```text


## Integration Notes


1. **Database Versioning**: Add these tables in database migration (increment database version)
2. **Backward Compatibility**: All new tables use `CREATE TABLE IF NOT EXISTS` for safe migration
3. **Foreign Keys**: CASCADE delete for execution history when scheduled report is deleted
4. **JSON Storage**: Use `json_encode()` for arrays/objects, `json_decode()` when reading
5. **Date Format**: Always use ISO 8601 format (`yyyy-MM-ddTHH:mm:ssZ`) for consistency


## Testing Queries


```sql
-- Get active scheduled reports due in next hour

SELECT * FROM scheduled_reports 

WHERE is_active = 1 
AND datetime(next_run) <= datetime('now', '+1 hour')
ORDER BY next_run ASC;

-- Get failed executions in last 24 hours

SELECT * FROM report_execution_history

WHERE status = 'failed'
AND datetime(executed_at) >= datetime('now', '-1 day')
ORDER BY executed_at DESC;

-- Get most accurate forecast model

SELECT * FROM forecast_models

WHERE is_active = 1
ORDER BY accuracy ASC
LIMIT 1;

-- Get shared custom templates

SELECT * FROM custom_report_templates

WHERE is_shared = 1
ORDER BY name ASC;
```text
