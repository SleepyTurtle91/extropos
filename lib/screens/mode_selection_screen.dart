// Deprecated: mode selection screen removed in favor of unified POS implementation.
// Retained as stub for compatibility; consider deleting later.

import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.shopping_cart, color: Colors.grey[800], size: 32),
        ),
        title: AnimatedBuilder(
          animation: BusinessSessionService(),
          builder: (context, child) {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cashier: SYSTEM',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Text(
                        'Date: ${DateTime.now().toString().substring(0, 16)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          AnimatedBuilder(
            animation: BusinessSessionService(),
            builder: (context, child) {
              final isOpen = BusinessSessionService().isBusinessOpen;
              return Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STATUS: ${isOpen ? "OPEN" : "CLOSED"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
            IconButton(
              icon: Icon(
                _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.grey[800],
              ),
              tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Enter Fullscreen',
              onPressed: _toggleFullscreen,
            ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.grey[800]),
            tooltip: 'Lock / Logout',
            onPressed: () {
              LockManager.instance.lock();
              Navigator.pushReplacementNamed(context, '/lock');
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive breakpoints for max content width
          final double maxContentWidth = (() {
            final w = constraints.maxWidth;
            if (w < 600) {
              return math.max(
                320.0,
                w - 48,
              ); // small screens - keep slight padding
            }
            if (w < 900) {
              return 600.0; // small tablet
            }
            if (w < 1200) {
              return 900.0; // tablet / small desktop
            }
            return 1100.0; // large desktop - slightly less than full width
          })();

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Training Mode Banner (if active)
                      AnimatedBuilder(
                        animation: AppSettings.instance,
                        builder: (context, child) {
                          if (!AppSettings.instance.isTrainingMode) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            margin: const EdgeInsets.only(bottom: 30),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'TRAINING MODE ACTIVE - Data will not be saved',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Switch(
                                  value: true,
                                  onChanged: (value) {
                                    AppSettings.instance.setTrainingMode(value);
                                  },
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: Colors.white24,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Mode Cards Grid - Using Stack + Positioned for perfect centering
                      SizedBox(
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: maxContentWidth,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Use a responsive Wrap so mode cards naturally flow on small screens
                                  return Wrap(
                                    spacing: 20,
                                    runSpacing: 16,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      // Build mode cards based on selected business mode
                                      if (BusinessInfo
                                              .instance
                                              .selectedBusinessMode ==
                                          BusinessMode.retail)
                                        _SimpleCard(
                                          title: 'POS',
                                          subtitle: '(Start Selling)',
                                          icon: Icons.shopping_cart,
                                          color: Colors.blue,
                                          onTap: () => _selectMode(
                                            context,
                                            BusinessMode.retail,
                                          ),
                                        ),
                                      if (BusinessInfo
                                              .instance
                                              .selectedBusinessMode ==
                                          BusinessMode.cafe)
                                        _SimpleCard(
                                          title: 'POS',
                                          subtitle: '(Start Selling)',
                                          icon: Icons.local_cafe,
                                          color: Colors.blue,
                                          onTap: () => _selectMode(
                                            context,
                                            BusinessMode.cafe,
                                          ),
                                        ),
                                      if (BusinessInfo
                                              .instance
                                              .selectedBusinessMode ==
                                          BusinessMode.restaurant)
                                        _SimpleCard(
                                          title: 'POS',
                                          subtitle: '(Start Selling)',
                                          icon: Icons.restaurant,
                                          color: Colors.blue,
                                          onTap: () => _selectMode(
                                            context,
                                            BusinessMode.restaurant,
                                          ),
                                        ),
                                      const SizedBox(width: 20),
                                      _SimpleCard(
                                        title: 'REPORTS',
                                        subtitle: '(View Data)',
                                        icon: Icons.bar_chart,
                                        color: Colors.green,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ReportsHomeScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 20),
                                      _SimpleCard(
                                        title: 'SETTINGS',
                                        subtitle: '(Configure)',
                                        icon: Icons.settings,
                                        color: Colors.grey,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const SettingsScreen(),
                                            ),
                                          ).then((_) => setState(() {}));
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // End Business Day Button
                      AnimatedBuilder(
                        animation: BusinessSessionService(),
                        builder: (context, child) {
                          final isOpen =
                              BusinessSessionService().isBusinessOpen;

                          return SizedBox(
                            width: 300,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => isOpen
                                      ? const CloseBusinessDialog()
                                      : const OpenBusinessDialog(),
                                );
                                if (result == true && mounted) {
                                  setState(() {});
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOpen
                                    ? Colors.red
                                    : Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                isOpen ? 'END BUSINESS DAY' : 'OPEN BUSINESS',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Tutorial button
                      TextButton.icon(
                        onPressed: _showTutorialDialog,
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Show Tutorial'),
                      ),
                    ],
                  ), // Column
                ), // Padding
              ), // ConstrainedBox
            ), // Center
          ); // SingleChildScrollView
        }, // builder
      ), // LayoutBuilder
      bottomSheet: _showTutorial
          ? TutorialOverlay(
              steps: _getTutorialSteps(),
              onComplete: _completeTutorial,
              onSkip: _skipTutorial,
            )
          : null,
    );
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
