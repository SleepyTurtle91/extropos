# Google Services Integration Guide

## Overview

FlutterPOS now includes integrated Google services for:

- **Gmail API**: Send scheduled reports via email with attachments

- **Google Drive API**: Sync database between multiple POS devices

## Features Implemented

### 1. Google Services Core (`lib/services/google_services.dart`)

**Authentication:**

- OAuth 2.0 via Google Sign-In

- Automatic token refresh

- Secure credential storage (flutter_secure_storage)

- Required scopes:

  - `gmail.send` - Send emails

  - `gmail.readonly` - Read emails (for confirmations)

  - `drive.file` - Access files created by the app

  - `drive.appdata` - App-specific data storage

**Gmail Integration:**

- `sendEmail()` - Send emails with HTML/plain text

- RFC 2822 compliant message formatting

- Support for:

  - Multiple recipients (To, CC, BCC)

  - HTML or plain text content

  - File attachments (PDF, CSV, Excel)

  - Base64 encoding for attachments

**Google Drive Integration:**

- `uploadToDrive()` - Upload files to Drive

- `downloadFromDrive()` - Download files from Drive

- `listDriveFiles()` - List files with query support

- `createDriveFolder()` - Create folders for organization

- `deleteDriveFile()` - Remove files

- `syncDatabaseToDrive()` - Backup database automatically

- `restoreDatabaseFromDrive()` - Restore from backup

- `listDatabaseBackups()` - View all available backups

### 2. Email Template Service (`lib/services/email_template_service.dart`)

**HTML Email Templates:**

- Professional responsive design

- Business branding (logo, name, address)

- Report-specific formatting:

  - Sales reports with metrics cards

  - Product performance rankings

  - Employee performance tables

  - Profit & loss statements

  - Comparative analysis with trends

**Features:**

- Responsive layout (mobile-friendly)

- Color-coded metrics (green = positive, red = negative)

- Attachment indicators

- Plain text fallback for non-HTML email clients

- Currency formatting (RM symbol, 2 decimals)

- Date/time formatting

### 3. Google Account Settings Screen (`lib/screens/google_account_settings_screen.dart`)

**Connection Management:**

- Sign in with Google button

- Display connected account email

- Disconnect option with confirmation

- Connection status indicator

**Cloud Backup:**

- One-click database backup to Drive

- Last sync timestamp display

- Progress indicator during sync

- Success/failure notifications

**Backup Management:**

- List all available backups

- Display backup metadata:

  - Filename

  - Creation date/time

  - File size

  - Device info (if available)

- Restore from selected backup

- Delete old backups

- Automatic backup before restore

**Permissions Display:**

- Shows granted permissions

- Explains scope usage

- Privacy information

## Setup Instructions

### 1. Google Cloud Console Setup

#### A. Create Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project: "FlutterPOS"
3. Note the Project ID

#### B. Enable APIs

1. Navigate to "APIs & Services" → "Library"
2. Enable:

   - Gmail API

   - Google Drive API

   - Google Sign-In API

#### C. Create OAuth Credentials

**For Android:**

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth 2.0 Client ID"
3. Select "Android"
4. Package name: `com.extrotarget.extropos.pos`
5. Get SHA-1 fingerprint:

   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

6. Copy SHA-1 and paste into form
7. Create and download JSON

**For iOS (if needed):**

1. Create OAuth Client ID → iOS
2. Bundle ID: `com.extrotarget.extropos`
3. Download plist file

**For Web (optional):**

1. Create OAuth Client ID → Web application
2. Authorized redirect URIs: `http://localhost` (for testing)

### 2. Flutter App Configuration

#### A. Update `pubspec.yaml`

Already configured with:

```yaml
dependencies:
  google_sign_in: ^6.2.1
  googleapis: ^11.4.0
  googleapis_auth: ^1.4.1
  http: ^1.1.0
  mailer: ^6.1.2
  flutter_secure_storage: ^9.0.0

```text


#### B. Android Configuration


**Add to `android/app/build.gradle.kts`:**


```kotlin
dependencies {
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}

```text

**Update `android/app/src/main/AndroidManifest.xml`:**


```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <application>
        <!-- Add Google Sign-In metadata -->
        <meta-data
            android:name="com.google.android.gms.version"
            android:value="@integer/google_play_services_version" />
    </application>
</manifest>

```text


#### C. iOS Configuration (if needed)


**Update `ios/Runner/Info.plist`:**


```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>

```text


### 3. Initialize Google Services


**In `main.dart`:**


```dart
import 'package:flutterpos/services/google_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Services
  await GoogleServices.instance.initialize();
  
  runApp(const MyApp());
}

```text


### 4. Add to Settings Menu


**In `lib/screens/settings_screen.dart`:**


```dart
ListTile(
  leading: Icon(Icons.cloud, color: Colors.blue),
  title: Text('Google Account'),
  subtitle: Text('Email delivery & cloud sync'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GoogleAccountSettingsScreen(),
      ),
    );
  },
),

```text


## Usage Examples



### Send Email with Report



```dart
import 'package:flutterpos/services/google_services.dart';
import 'package:flutterpos/services/email_template_service.dart';

Future<void> sendScheduledReport({
  required String reportName,
  required String reportType,
  required ReportPeriod period,
  required Map<String, dynamic> reportData,
  required List<String> recipients,
  List<EmailAttachment>? attachments,
}) async {
  final googleServices = GoogleServices.instance;
  final templateService = EmailTemplateService.instance;
  
  // Check if signed in
  if (!googleServices.isSignedIn) {
    throw Exception('Not signed in to Google');
  }
  
  // Generate HTML email
  final htmlBody = templateService.generateScheduledReportEmail(
    reportType: reportType,
    reportName: reportName,
    period: period,
    reportData: reportData,
    attachmentFilenames: attachments?.map((a) => a.filename).toList(),
  );
  
  // Send email
  for (final recipient in recipients) {
    final success = await googleServices.sendEmail(
      to: recipient,
      subject: '$reportName - ${period.label}',
      body: htmlBody,
      attachments: attachments,
      isHtml: true,
    );
    
    if (success) {
      print('Email sent to $recipient');
    } else {
      print('Failed to send email to $recipient');
    }
  }
}

```text


### Backup Database to Drive



```dart
import 'package:flutterpos/services/google_services.dart';
import 'package:flutterpos/services/database_helper.dart';
import 'dart:io';

Future<bool> backupDatabaseToCloud() async {
  final googleServices = GoogleServices.instance;
  
  if (!googleServices.isSignedIn) {
    print('Please sign in to Google first');
    return false;
  }
  
  // Get database file
  final dbPath = await DatabaseHelper.instance.getDatabasePath();
  final dbFile = File(dbPath);
  
  // Backup to Drive
  final success = await googleServices.syncDatabaseToDrive(
    databaseFile: dbFile,
  );
  
  return success;
}

```text


### Restore Database from Drive



```dart
Future<bool> restoreDatabaseFromCloud(String backupFileId) async {
  final googleServices = GoogleServices.instance;
  
  // Get target database path
  final dbPath = await DatabaseHelper.instance.getDatabasePath();
  final dbFile = File(dbPath);
  
  // Restore from Drive
  final success = await googleServices.restoreDatabaseFromDrive(
    fileId: backupFileId,
    targetDatabaseFile: dbFile,
  );
  
  if (success) {
    print('Database restored. Please restart the app.');
  }
  
  return success;
}

```text


### List Available Backups



```dart
Future<void> showAvailableBackups() async {
  final googleServices = GoogleServices.instance;
  
  final backups = await googleServices.listDatabaseBackups();
  
  for (final backup in backups) {
    print('Backup: ${backup.name}');
    print('Created: ${backup.createdTime}');
    print('Size: ${backup.size} bytes');
    print('ID: ${backup.id}');
    print('---');
  }
}

```text


## Dual-Counter Sync Workflow



### Scenario: Two POS devices sharing data


**Device A (Primary):**

1. Complete sales transactions
2. Go to Settings → Google Account
3. Click "Backup Now"
4. Database uploaded to Drive as `flutterpos_backup_2025-XX-XX.db`

**Device B (Secondary):**

1. Go to Settings → Google Account
2. View "Available Backups" list
3. Select latest backup from Device A
4. Click restore icon
5. Confirm restore (current database backed up first)
6. App restarts with synced data

**Best Practices:**


- Backup at end of each shift

- Keep at least 3 backups (daily, weekly, monthly)

- Verify backup size matches expected database size

- Test restore on non-production device first


## Security Considerations



### OAuth 2.0 Security


- Credentials stored in flutter_secure_storage (encrypted)

- Access tokens expire after 1 hour

- Refresh tokens used for seamless renewal

- No password storage (OAuth flow only)


### Drive Access Scope


- App only accesses files it creates

- Cannot read other Drive files

- Backup folder: "FlutterPOS Backups"

- File MIME type: `application/x-sqlite3`


### Email Privacy


- Emails sent from user's Gmail account

- No FlutterPOS email server involved

- Attachments stored temporarily, deleted after send

- No email tracking or analytics


### Recommended Practices


1. Use Google Workspace account (not personal Gmail)
2. Enable 2FA on Google account
3. Review connected apps regularly
4. Rotate backups (delete old backups after 90 days)
5. Encrypt database before upload (future enhancement)


## Troubleshooting



### "Failed to authenticate with Google"


- Verify OAuth credentials in Google Cloud Console

- Check package name matches (com.extrotarget.extropos.pos)

- Ensure SHA-1 fingerprint is correct

- Try signing out and back in


### "Email sending failed"


- Check internet connection

- Verify Gmail API is enabled in Cloud Console

- Check Gmail quota (500 emails/day for free accounts)

- Ensure recipient email is valid


### "Backup not found"


- Sign in with the same Google account used for backup

- Check "FlutterPOS Backups" folder in Drive

- Verify file wasn't manually deleted

- Try refreshing backup list


### "Restore failed"


- Ensure backup file is not corrupted

- Check available storage space

- Close app completely before restoring

- Check file permissions


## API Quotas and Limits



### Gmail API


- **Free tier**: 500 emails/day per account

- **Workspace**: 2,000 emails/day per account

- Attachment size limit: 25 MB per email

- Rate limit: 1 request/second (handled automatically)


### Google Drive API


- **Free tier**: 15 GB storage

- **Workspace**: 30 GB - Unlimited (depending on plan)

- Upload limit: 5 TB per file

- Rate limit: 1,000 requests/100 seconds/user


### Best Practices to Avoid Quota Issues


1. Batch email sends (delay between emails)
2. Compress database before backup (gzip)
3. Delete old backups to save storage
4. Use scheduled reports wisely (not every hour)
5. Monitor quota usage in Cloud Console


## Future Enhancements



### Planned Features


- [ ] Database encryption before upload

- [ ] Incremental backup (only changed data)

- [ ] Automatic conflict resolution (merge strategies)

- [ ] Email delivery queue (retry failed sends)

- [ ] Gmail inbox integration (receive customer orders)

- [ ] Drive folder sharing (multi-user access)

- [ ] Two-way sync (bidirectional updates)

- [ ] Backup scheduling (daily, weekly, monthly)

- [ ] Backup retention policy (auto-delete old backups)

- [ ] Email templates customization (user-editable HTML)


### Integration with Advanced Reporting


Once background scheduler is implemented:

1. Scheduled reports will automatically send via Gmail
2. Attachments (PDF/CSV/Excel) generated and attached
3. Execution history logged in database
4. Email delivery failures tracked and retried


## Support


For issues or questions:

1. Check logs: Settings → App Logs
2. Verify Google Cloud Console configuration
3. Test with a fresh Google account
4. Review network connectivity
5. Check FlutterPOS documentation


## Version History


- **v1.0.14**: Initial Google services integration

  - Gmail API for email delivery

  - Google Drive for database sync

  - OAuth 2.0 authentication

  - HTML email templates

  - Backup/restore UI
