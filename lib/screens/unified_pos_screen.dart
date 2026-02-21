import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/business_mode.dart';
import 'package:extropos/screens/cafe_pos_screen.dart';
import 'package:extropos/screens/order_queue_screen.dart';
import 'package:extropos/screens/pos/retail_pos_refactored.dart';
import 'package:extropos/screens/reports_home_screen.dart';
import 'package:extropos/screens/settings_screen.dart';
import 'package:extropos/screens/shift/end_shift_dialog.dart';
import 'package:extropos/screens/shift/start_shift_dialog.dart';
import 'package:extropos/screens/table_selection_screen.dart';
import 'package:extropos/screens/user/sign_in_dialog.dart';
import 'package:extropos/screens/user/sign_out_dialog_simple.dart';
import 'package:extropos/services/business_session_service.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/shift_service.dart';
import 'package:extropos/services/training_mode_service.dart';
import 'package:extropos/services/user_session_service.dart';
import 'package:extropos/widgets/business_session_dialogs.dart';
import 'package:flutter/material.dart';

/// Unified POS screen that routes to the appropriate mode based on BusinessInfo.instance.selectedBusinessMode
/// and provides a burger menu with Settings, Reports, and Business session controls
class UnifiedPOSScreen extends StatefulWidget {
  const UnifiedPOSScreen({super.key});

  @override
  State<UnifiedPOSScreen> createState() => _UnifiedPOSScreenState();
}

class _UnifiedPOSScreenState extends State<UnifiedPOSScreen> {
  final GlobalKey _cafeKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final selectedMode = BusinessInfo.instance.selectedBusinessMode;
    developer.log(
      'UnifiedPOSScreen: selectedMode=${selectedMode.displayName}',
      name: 'unified_pos',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('ExtroPOS — ${selectedMode.displayName} Mode'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          AnimatedBuilder(
            animation: BusinessInfo.instance,
            builder: (context, _) {
              final info = BusinessInfo.instance;
              final enabled = info.isMyInvoisEnabled;
              final sandbox = info.useMyInvoisSandbox;
              final color = !enabled
                  ? Colors.grey
                  : sandbox
                      ? Colors.blue
                      : Colors.redAccent;
              final label = !enabled
                  ? 'MyInvois: Off'
                  : sandbox
                      ? 'MyInvois: Sandbox'
                      : 'MyInvois: Production';

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      sandbox ? Icons.science : Icons.receipt_long,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (selectedMode == BusinessMode.cafe) ...[
            IconButton(
              tooltip: 'Active Orders',
              icon: const Icon(Icons.list_alt),
              onPressed: () {
                final st = _cafeKey.currentState;
                if (st != null) {
                  try {
                    (st as dynamic).showActiveOrders();
                  } catch (e) {
                    developer.log(
                      'Failed to open active orders from AppBar: $e',
                    );
                  }
                }
              },
            ),
            IconButton(
              tooltip: 'Order Queue Display',
              icon: const Icon(Icons.monitor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderQueueScreen(),
                  ),
                );
              },
            ),
          ],
          // Business status indicator
          AnimatedBuilder(
            animation: BusinessSessionService(),
            builder: (context, child) {
              final isOpen = BusinessSessionService().isBusinessOpen;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOpen ? 'OPEN' : 'CLOSED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
          // Current user indicator
          AnimatedBuilder(
            animation: UserSessionService(),
            builder: (context, child) {
              final currentUser = UserSessionService().currentActiveUser;
              if (currentUser == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      currentUser.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Burger menu
          AnimatedBuilder(
            animation: TrainingModeService.instance,
            builder: (context, _) {
              if (!TrainingModeService.instance.isTrainingMode)
                return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.school, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'TRAINING',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) async {
              switch (value) {
                case 'settings':
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  // Refresh in case settings changed mode
                  if (mounted) setState(() {});
                  break;
                case 'reports':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsHomeScreen(),
                    ),
                  );
                  break;
                case 'user_signin':
                  if (UserSessionService().hasActiveUser) {
                    // Sign out
                    await showDialog(
                      context: context,
                      builder: (context) => const SignOutDialogSimple(),
                    );
                  } else {
                    // Sign in
                    await showDialog(
                      context: context,
                      builder: (context) => const SignInDialog(),
                    );
                  }
                  if (mounted) setState(() {});
                  break;
                case 'shift_management':
                  final currentUser = LockManager.instance.currentUser;
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No user logged in')),
                    );
                    return;
                  }

                  final shiftService = ShiftService.instance;
                  final hasActiveShift = shiftService.hasActiveShift;

                  if (hasActiveShift) {
                    // End shift
                    final shift = shiftService.currentShift!;
                    await showDialog(
                      context: context,
                      builder: (context) => EndShiftDialog(shift: shift),
                    );
                  } else {
                    // Start shift
                    await showDialog(
                      context: context,
                      builder: (context) =>
                          StartShiftDialog(userId: currentUser.id),
                    );
                  }
                  break;
                case 'business_session':
                  final isOpen = BusinessSessionService().isBusinessOpen;
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => isOpen
                        ? const CloseBusinessDialog()
                        : const OpenBusinessDialog(),
                  );
                  if (result == true && mounted) {
                    setState(() {});
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'user_signin',
                child: Row(
                  children: [
                    Icon(
                      UserSessionService().hasActiveUser
                          ? Icons.person_off
                          : Icons.person_add,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      UserSessionService().hasActiveUser
                          ? 'Sign Out Cashier'
                          : 'Sign In Cashier',
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'shift_management',
                child: Row(
                  children: [
                    Icon(
                      ShiftService.instance.hasActiveShift
                          ? Icons.logout
                          : Icons.login,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ShiftService.instance.hasActiveShift
                          ? 'End Shift'
                          : 'Start Shift',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'business_session',
                child: Row(
                  children: [
                    Icon(
                      BusinessSessionService().isBusinessOpen
                          ? Icons.business_center
                          : Icons.business_center_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      BusinessSessionService().isBusinessOpen
                          ? 'End Business Day'
                          : 'Open Business',
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reports',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 20),
                    SizedBox(width: 12),
                    Text('Reports'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: BusinessSessionService(),
        builder: (context, child) {
          // Check if business is open
          if (!BusinessSessionService().isBusinessOpen) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.business_center,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Business is currently closed',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please open the business from the menu to access POS features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => const OpenBusinessDialog(),
                      );
                      if (result == true && mounted) {
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.business_center_outlined),
                    label: const Text('Open Business'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Route to the appropriate POS screen based on selected mode
          // Build POS content in a stack so we can display a training-mode overlay
          Widget posContent;
          switch (selectedMode) {
            case BusinessMode.retail:
              // show the refactored retail POS screen
              posContent = const RetailPosRefactorScreen();
              break;
            case BusinessMode.cafe:
              posContent = CafePOSScreen(key: _cafeKey);
              break;
            case BusinessMode.restaurant:
              posContent = const TableSelectionScreen();
              break;
          }

          return Stack(
            children: [
              posContent,
              // Training mode overlay
              AnimatedBuilder(
                animation: TrainingModeService.instance,
                builder: (context, _) {
                  if (!TrainingModeService.instance.isTrainingMode)
                    return const SizedBox.shrink();
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.orange.withOpacity(0.95),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.school, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'TRAINING MODE — No data will be saved',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
