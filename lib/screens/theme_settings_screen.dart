import 'package:extropos/models/app_theme_model.dart';
import 'package:extropos/services/theme_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  final _themeService = ThemeService();
  late AppTheme _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = _themeService.currentTheme;
  }

  Future<void> _applyTheme(AppTheme theme) async {
    setState(() {
      _selectedTheme = theme;
    });

    await _themeService.setThemeObject(theme);

    if (mounted) {
      ToastHelper.showToast(context, 'Theme applied: ${theme.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightThemes = AppThemes.allThemes
        .where((t) => t.brightness == Brightness.light)
        .toList();
    final darkThemes = AppThemes.allThemes
        .where((t) => t.brightness == Brightness.dark)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme & Color Scheme'),
        backgroundColor: _selectedTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _themeService.resetToDefault();
              setState(() {
                _selectedTheme = _themeService.currentTheme;
              });
              if (mounted) {
                ToastHelper.showToast(context, 'Reset to default theme');
              }
            },
            tooltip: 'Reset to Default',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Info
          Card(
            color: _selectedTheme.primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.palette,
                    color: _selectedTheme.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Theme: ${_selectedTheme.name}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _selectedTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTheme.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedTheme.primaryColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Light Themes Section
          _buildSectionHeader('☀️ Light Themes', Icons.wb_sunny),
          const SizedBox(height: 12),
          ...lightThemes.map((theme) => _buildThemeCard(theme)),

          const SizedBox(height: 24),

          // Dark Themes Section
          _buildSectionHeader('🌙 Dark Themes', Icons.dark_mode),
          const SizedBox(height: 12),
          ...darkThemes.map((theme) => _buildThemeCard(theme)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _selectedTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _selectedTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(AppTheme theme) {
    final isSelected = _selectedTheme.id == theme.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _applyTheme(theme),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? theme.primaryColor : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          theme.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: theme.primaryColor,
                      size: 28,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Color Preview Swatches
              Row(
                children: [
                  _buildColorSwatch('Primary', theme.primaryColor),
                  const SizedBox(width: 8),
                  _buildColorSwatch('Secondary', theme.secondaryColor),
                  const SizedBox(width: 8),
                  _buildColorSwatch('Accent', theme.accentColor),
                  const SizedBox(width: 8),
                  _buildColorSwatch('Success', theme.successColor),
                ],
              ),

              const SizedBox(height: 12),

              // Preview Button
              Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Preview Button',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSwatch(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
