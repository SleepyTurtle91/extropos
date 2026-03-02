// Deprecated: mode selection screen removed in favor of unified POS implementation.
// Retained as stub for compatibility; consider deleting later.

import 'package:flutter/material.dart';

part 'mode_selection_screen_ui.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  bool _showTutorial = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _initializeBusinessSession();
  }

  Future<void> _initializeBusinessSession() async {
    await BusinessSessionService().initialize();
  }

  Future<void> _checkFirstTime() async {
    await AppSettings.instance.init();

    if (!AppSettings.instance.hasSeenTutorial && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showTutorial = true;
          });
        }
      });
    }
  }

  void _selectMode(BuildContext context, BusinessMode mode) {
    if (_showTutorial) return;

    if (!BusinessSessionService().isBusinessOpen) {
      ToastHelper.showToast(
        context,
        'Please open business first to access POS features',
      );
      return;
    }

    BusinessInfo.updateInstance(
      BusinessInfo.instance.copyWith(selectedBusinessMode: mode),
    );

    Navigator.pushNamed(context, '/pos');
  }

  void _showTutorialDialog() {
    setState(() {
      _showTutorial = true;
    });
  }

  void _completeTutorial() {
    AppSettings.instance.markTutorialAsSeen();
    setState(() {
      _showTutorial = false;
    });
  }

  void _skipTutorial() {
    AppSettings.instance.markTutorialAsSeen();
    setState(() {
      _showTutorial = false;
    });
  }

  Future<void> _toggleFullscreen() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

    try {
      if (_isFullscreen) {
        await windowManager.setFullScreen(false);
        setState(() => _isFullscreen = false);
      } else {
        await windowManager.setFullScreen(true);
        setState(() => _isFullscreen = true);
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(
          context,
          'Fullscreen not supported on this platform',
        );
      }
    }
  }

  List<TutorialStep> _getTutorialSteps() {
    return [
      TutorialStep(
        title: 'Welcome to ExtroPOS!',
        description:
            'Your complete Point of Sale solution for retail, cafe, and restaurant businesses. Let\'s get you started with a quick tour.',
        icon: Icons.waving_hand,
      ),
      TutorialStep(
        title: 'Training Mode',
        description:
            'Use Training Mode to practice without affecting real data. Perfect for learning the system or training new staff members.',
        icon: Icons.school,
      ),
      TutorialStep(
        title: 'Choose Your Business Type',
        description:
            'Select Retail for product sales, Cafe for quick service, or Restaurant for table service. You can switch between modes anytime.',
        icon: Icons.business,
      ),
      TutorialStep(
        title: 'Settings & Configuration',
        description:
            'Access Settings to configure categories, items, printers, users, and more. Customize ExtroPOS to fit your business needs.',
        icon: Icons.settings,
      ),
      TutorialStep(
        title: 'Ready to Start!',
        description:
            'You\'re all set! Select a business mode to begin. Need help? Look for the guide icon throughout the app.',
        icon: Icons.check_circle,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('See mode_selection_screen_ui.dart');
  }
}
}

class _SimpleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SimpleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Make card responsive: constrain width but allow wrap/stacking
            final cardMaxWidth = constraints.maxWidth > 260
                ? 260.0
                : constraints.maxWidth;
            return ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 140,
                maxWidth: cardMaxWidth,
                minHeight: 160,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: color.withAlpha((0.15 * 255).round()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 48, color: color),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
