# Google Services Quick Reference

## Quick Start

### 1. Sign In

```dart
final googleServices = GoogleServices.instance;
await googleServices.initialize();

final success = await googleServices.signIn();
if (success) {
  print('Signed in as: ${googleServices.userEmail}');
}
```text


### 2. Send Email


```dart
final success = await googleServices.sendEmail(
  to: 'customer@example.com',
  subject: 'Daily Sales Report',
  body: '<h1>Sales: RM 1,234.56</h1>',
  isHtml: true,
  attachments: [
    EmailAttachment.pdf(
      filename: 'sales_report.pdf',
      pdfBytes: pdfBytes,
    ),
  ],
);
```text


### 3. Backup Database


```dart
final dbPath = await DatabaseHelper.instance.getDatabasePath();
final dbFile = File(dbPath);

final success = await googleServices.syncDatabaseToDrive(
  databaseFile: dbFile,
);
```text


### 4. List Backups


```dart
final backups = await googleServices.listDatabaseBackups();
for (final backup in backups) {
  print('${backup.name} - ${backup.createdTime}');

}
```text


### 5. Restore Backup


```dart
final dbPath = await DatabaseHelper.instance.getDatabasePath();
final dbFile = File(dbPath);

final success = await googleServices.restoreDatabaseFromDrive(
  fileId: backupFileId,
  targetDatabaseFile: dbFile,
);
```text


## Email Templates



### Generate HTML Email


```dart
final emailService = EmailTemplateService.instance;

final html = emailService.generateScheduledReportEmail(
  reportType: 'Daily Sales',
  reportName: 'End of Day Report',
  period: ReportPeriod.today(),
  reportData: {
    'totalSales': 1234.56,
    'transactionCount': 45,
    'taxAmount': 123.45,
  },
  attachmentFilenames: ['report.pdf', 'report.csv'],
);
```text


### Report Data Format


**Sales Report:**

```dart
{
  'totalSales': double,
  'transactionCount': int,
  'taxAmount': double,
}
```text

**Product Performance:**

```dart
{
  'topProducts': [
    {'name': 'Product A', 'quantity': 10, 'revenue': 100.0},
    {'name': 'Product B', 'quantity': 8, 'revenue': 80.0},
  ],
}
```text

**Employee Performance:**

```dart
{
  'employees': [
    {'name': 'John', 'totalSales': 500.0, 'transactionCount': 20},
    {'name': 'Jane', 'totalSales': 450.0, 'transactionCount': 18},
  ],
}
```text

**Profit & Loss:**

```dart
{
  'revenue': 1000.0,
  'costs': 600.0,
}
```text

**Comparative Analysis:**

```dart
{
  'currentPeriod': {'totalSales': 1000.0},
  'previousPeriod': {'totalSales': 900.0},
}
```text


## Attachment Types



### PDF


```dart
EmailAttachment.pdf(
  filename: 'report.pdf',
  pdfBytes: await generatePDF(),
)
```text


### CSV


```dart
EmailAttachment.csv(
  filename: 'data.csv',
  csvBytes: utf8.encode(csvString),
)
```text


### Excel


```dart
EmailAttachment.excel(
  filename: 'spreadsheet.xlsx',
  excelBytes: await generateExcel(),
)
```text


### Custom


```dart
EmailAttachment.fromBytes(
  filename: 'data.json',
  mimeType: 'application/json',
  bytes: utf8.encode(jsonString),
)
```text


## Drive Operations



### Upload File


```dart
final fileId = await googleServices.uploadToDrive(
  filename: 'my_file.txt',
  fileBytes: utf8.encode('Hello, Drive!'),
  mimeType: 'text/plain',
  metadata: {'description': 'Test file'},
);
```text


### Download File


```dart
final bytes = await googleServices.downloadFromDrive(fileId);
final content = utf8.decode(bytes);
```text


### List Files


```dart
final files = await googleServices.listDriveFiles(
  query: "name contains 'backup'",
  pageSize: 20,
);
```text


### Create Folder


```dart
final folderId = await googleServices.createDriveFolder(
  folderName: 'My Reports',
);
```text


### Delete File


```dart
final success = await googleServices.deleteDriveFile(fileId);
```text


## Error Handling



### Check Sign-In Status


```dart
if (!googleServices.isSignedIn) {
  throw Exception('Please sign in to Google first');
}
```text


### Handle Email Errors


```dart
try {
  final success = await googleServices.sendEmail(/* ... */);
  if (success) {
    print('Email sent');
  } else {
    print('Email failed (check console for details)');
  }
} catch (e) {
  print('Error sending email: $e');
}
```text


### Handle Drive Errors


```dart
try {
  final fileId = await googleServices.uploadToDrive(/* ... */);
  if (fileId != null) {
    print('Uploaded: $fileId');
  } else {
    print('Upload failed');
  }
} catch (e) {
  print('Error uploading: $e');
}
```text


## Common Patterns



### Send Report with Attachments


```dart
Future<bool> sendReportEmail({
  required String recipient,
  required String reportName,
  required Map<String, dynamic> reportData,
  required List<int> pdfBytes,
  required List<int> csvBytes,
}) async {
  final emailService = EmailTemplateService.instance;
  final googleServices = GoogleServices.instance;
  
  // Generate HTML
  final html = emailService.generateScheduledReportEmail(
    reportType: 'Sales',
    reportName: reportName,
    period: ReportPeriod.today(),
    reportData: reportData,
    attachmentFilenames: ['report.pdf', 'report.csv'],
  );
  
  // Create attachments
  final attachments = [
    EmailAttachment.pdf(filename: 'report.pdf', pdfBytes: pdfBytes),
    EmailAttachment.csv(filename: 'report.csv', csvBytes: csvBytes),
  ];
  
  // Send
  return await googleServices.sendEmail(
    to: recipient,
    subject: '$reportName - ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
    body: html,
    attachments: attachments,
    isHtml: true,
  );
}
```text


### Automatic Daily Backup


```dart
Future<void> performDailyBackup() async {
  final googleServices = GoogleServices.instance;
  
  if (!googleServices.isSignedIn) {
    print('Not signed in - skipping backup');
    return;
  }
  
  final dbPath = await DatabaseHelper.instance.getDatabasePath();
  final dbFile = File(dbPath);
  
  final success = await googleServices.syncDatabaseToDrive(
    databaseFile: dbFile,
  );
  
  if (success) {
    print('Daily backup completed');
    
    // Clean up old backups (keep last 7 days)
    final backups = await googleServices.listDatabaseBackups();
    if (backups.length > 7) {
      final oldBackups = backups.sublist(7);
      for (final backup in oldBackups) {
        await googleServices.deleteDriveFile(backup.id!);
      }
    }
  }
}
```text


### Sync Between Devices


```dart
// Device A: Backup
await googleServices.syncDatabaseToDrive(
  databaseFile: File(await DatabaseHelper.instance.getDatabasePath()),
);

// Device B: Restore latest
final backups = await googleServices.listDatabaseBackups();
if (backups.isNotEmpty) {
  final latest = backups.first;
  await googleServices.restoreDatabaseFromDrive(
    fileId: latest.id!,
    targetDatabaseFile: File(await DatabaseHelper.instance.getDatabasePath()),
  );
  // Restart app
}
```text


## Testing



### Mock Google Services


```dart
// For testing, create a mock implementation:
class MockGoogleServices extends GoogleServices {
  @override
  Future<bool> sendEmail({/* ... */}) async {
    print('MOCK: Would send email to $to');
    return true;
  }
  
  @override
  Future<String?> uploadToDrive({/* ... */}) async {
    print('MOCK: Would upload ${filename}');
    return 'mock_file_id_123';
  }
}
```text


### Test Email Template


```dart
void testEmailTemplate() {
  final service = EmailTemplateService.instance;
  final html = service.generateScheduledReportEmail(
    reportType: 'Test',
    reportName: 'Test Report',
    period: ReportPeriod.today(),
    reportData: {'totalSales': 100.0},
  );
  
  // Save to file for visual inspection
  File('test_email.html').writeAsStringSync(html);
  print('Open test_email.html in browser');
}
```text


## Configuration



### OAuth Scopes


```dart
// Required scopes (already configured in GoogleServices):
final scopes = [
  'https://www.googleapis.com/auth/gmail.send',
  'https://www.googleapis.com/auth/gmail.readonly',
  'https://www.googleapis.com/auth/drive.file',
  'https://www.googleapis.com/auth/drive.appdata',
];
```text


### Google Cloud Console


1. Enable APIs: Gmail API, Google Drive API
2. Create OAuth 2.0 Client ID (Android/iOS)
3. Add SHA-1 fingerprint (Android)
4. Download configuration files


## Troubleshooting



### "Not signed in"


```dart
await googleServices.initialize();
await googleServices.signIn();
```text


### "Email quota exceeded"


- Free Gmail: 500 emails/day

- Use Google Workspace for higher limits


### "Drive storage full"


- Free: 15 GB

- Delete old backups

- Upgrade to paid plan


### "Auth token expired"


```dart
// Auto-refresh is built-in, but to manually refresh:
await googleServices.signOut();
await googleServices.signIn();
```text


## API Reference



### GoogleServices


**Properties:**


- `isSignedIn: bool` - Check if user is authenticated

- `userEmail: String?` - Current user's email address

**Methods:**


- `initialize()` - Initialize Google Sign-In

- `signIn()` - Sign in with Google account

- `signOut()` - Sign out and clear credentials

- `sendEmail()` - Send email via Gmail API

- `uploadToDrive()` - Upload file to Drive

- `downloadFromDrive()` - Download file from Drive

- `listDriveFiles()` - List Drive files with query

- `createDriveFolder()` - Create folder in Drive

- `deleteDriveFile()` - Delete file from Drive

- `syncDatabaseToDrive()` - Backup database to Drive

- `restoreDatabaseFromDrive()` - Restore database from Drive

- `listDatabaseBackups()` - List all database backups


### EmailTemplateService


**Methods:**


- `generateScheduledReportEmail()` - Generate HTML email for report

- `generatePlainTextEmail()` - Generate plain text version


### EmailAttachment


**Factory Constructors:**


- `fromBytes()` - Create from byte array

- `pdf()` - Create PDF attachment

- `csv()` - Create CSV attachment

- `excel()` - Create Excel attachment

**Properties:**


- `filename: String` - Attachment filename

- `mimeType: String` - MIME type

- `base64Content: String` - Base64 encoded content


## Performance Tips


1. **Batch Operations**: Delay between emails to avoid rate limits
2. **Compress Backups**: Reduce upload time (future enhancement)
3. **Background Sync**: Use background tasks for automatic backups
4. **Cache Backups List**: Don't refresh on every screen load
5. **Lazy Load**: Initialize Google Services only when needed


## Security Best Practices


1. **Use Workspace Account**: Better quota and security
2. **Enable 2FA**: Two-factor authentication on Google account
3. **Review Permissions**: Regularly check connected apps
4. **Rotate Backups**: Delete old backups after 90 days
5. **Monitor Usage**: Check Cloud Console for unusual activity
