import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  Future<String> _loadChangelog() async {
    try {
      return await rootBundle.loadString('CHANGELOG.md');
    } catch (e) {
      return '''# Changelog

## [1.1.4] - ${DateTime.now().toString().split(' ')[0]}

### Fixed
- **App Icon**: Generated launcher icons for Android and iOS
- **Products Loading**: Implemented database fetch in UnifiedPOSScreen to properly load categories and products
- **Icon Display**: Fixed icon rendering throughout the app by properly converting icon code points from database

### Technical Details
- Fixed `_iconFromDb()` method to properly convert database icon code points to IconData
- Added DatabaseService integration to UnifiedPOSScreen for loading products and categories
- Generated app icons using flutter_launcher_icons package

---

## [1.1.3] - 2026-02-20

### Added
- Initial multi-mode POS system (Retail, Cafe, Restaurant)
- Business session management
- Shift management for cashiers
- User authentication system
- Training mode support

### Fixed
- Various UI improvements
- Database optimization
- Performance enhancements

---

View complete changelog at: https://github.com/yourusername/extropos
''';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changelog'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: _loadChangelog(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load changelog',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Version History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'All notable changes to ExtroPOS',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Markdown(
                  data: snapshot.data ?? '',
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    h1: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                    h2: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    h3: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    p: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey[800],
                    ),
                    listBullet: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2563EB),
                    ),
                    code: TextStyle(
                      backgroundColor: Colors.grey[100],
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    blockquote: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      launchUrl(Uri.parse(href));
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
