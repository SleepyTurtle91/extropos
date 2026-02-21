import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/user_session_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check if current user has a specific permission
  bool hasPermission(String permissionKey) {
    final currentUser = UserSessionService().currentActiveUser;
    if (currentUser == null) return false;

    final permissions = currentUser.permissions;
    switch (permissionKey) {
      case 'canAccessPOS':
        return permissions.canAccessPOS;
      case 'canProcessSales':
        return permissions.canProcessSales;
      case 'canSignInOut':
        return permissions.canSignInOut;
      case 'canApplyDiscounts':
        return permissions.canApplyDiscounts;
      case 'canVoidItemsAfterPrinting':
        return permissions.canVoidItemsAfterPrinting;
      case 'canProcessRefunds':
        return permissions.canProcessRefunds;
      case 'canVoidPaidTransactions':
        return permissions.canVoidPaidTransactions;
      case 'canOpenCashDrawerNoSale':
        return permissions.canOpenCashDrawerNoSale;
      case 'canViewExpectedCash':
        return permissions.canViewExpectedCash;
      case 'canPerformBlindCount':
        return permissions.canPerformBlindCount;
      case 'canPerformShiftEnd':
        return permissions.canPerformShiftEnd;
      case 'canPerformDayClosing':
        return permissions.canPerformDayClosing;
      case 'canAcknowledgeVariance':
        return permissions.canAcknowledgeVariance;
      case 'canEditTaxSettings':
        return permissions.canEditTaxSettings;
      case 'canExemptSST':
        return permissions.canExemptSST;
      case 'canManageUsers':
        return permissions.canManageUsers;
      case 'canManageItems':
        return permissions.canManageItems;
      case 'canManageTables':
        return permissions.canManageTables;
      case 'canViewReports':
        return permissions.canViewReports;
      case 'canManageBusinessSettings':
        return permissions.canManageBusinessSettings;
      case 'canOpenCloseBusiness':
        return permissions.canOpenCloseBusiness;
      case 'canManagePrinters':
        return permissions.canManagePrinters;
      case 'canManagePaymentMethods':
        return permissions.canManagePaymentMethods;
      default:
        return false;
    }
  }

  /// Check if current user can perform an action requiring higher permissions
  Future<bool> canPerformActionWithElevation(
    BuildContext context,
    String requiredPermission,
    String actionDescription,
  ) async {
    // First check if current user already has the permission
    if (hasPermission(requiredPermission)) {
      return true;
    }

    // If not, show PIN verification dialog for manager/supervisor override
    final authorized = await _showAuthorizationDialog(
      context,
      requiredPermission,
      actionDescription,
    );

    return authorized;
  }

  /// Show authorization dialog for restricted actions
  Future<bool> _showAuthorizationDialog(
    BuildContext context,
    String requiredPermission,
    String actionDescription,
  ) async {
    final pinController = TextEditingController();
    String? errorMessage;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Authorization Required'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current user does not have permission to $actionDescription.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter Manager or Supervisor PIN to authorize:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter PIN',
                      errorText: errorMessage,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (errorMessage != null) {
                        setState(() => errorMessage = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pin = pinController.text.trim();
                    if (pin.isEmpty) {
                      setState(() => errorMessage = 'PIN is required');
                      return;
                    }

                    // Verify PIN and check if user has required permission
                    final authorizedUser = await DatabaseService.instance
                        .findUserByPin(pin);
                    if (authorizedUser == null) {
                      setState(() => errorMessage = 'Invalid PIN');
                      return;
                    }

                    // Check if authorizing user has the required permission
                    final authPermissions = authorizedUser.permissions;
                    bool hasAuthPermission = false;

                    switch (requiredPermission) {
                      case 'canApplyDiscounts':
                      case 'canVoidItemsAfterPrinting':
                      case 'canOpenCashDrawerNoSale':
                      case 'canExemptSST':
                        hasAuthPermission =
                            authPermissions.canApplyDiscounts ||
                            authPermissions.canVoidItemsAfterPrinting ||
                            authPermissions.canOpenCashDrawerNoSale ||
                            authPermissions.canExemptSST;
                        break;
                      case 'canVoidPaidTransactions':
                      case 'canViewExpectedCash':
                      case 'canPerformDayClosing':
                      case 'canAcknowledgeVariance':
                      case 'canEditTaxSettings':
                        hasAuthPermission =
                            authPermissions.canVoidPaidTransactions ||
                            authPermissions.canViewExpectedCash ||
                            authPermissions.canPerformDayClosing ||
                            authPermissions.canAcknowledgeVariance ||
                            authPermissions.canEditTaxSettings;
                        break;
                      default:
                        hasAuthPermission = false;
                    }

                    if (!hasAuthPermission) {
                      setState(
                        () => errorMessage =
                            'User does not have authorization for this action',
                      );
                      return;
                    }

                    // Success - return authorized user info for logging
                    ToastHelper.showToast(
                      context,
                      'Action authorized by ${authorizedUser.fullName} (${authorizedUser.roleDisplayName})',
                    );
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Authorize'),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  /// Get permission description for UI display
  String getPermissionDescription(String permissionKey) {
    final definitions = RolePermissions.getPermissionDefinitions();
    final definition = definitions.firstWhere(
      (def) => def['key'] == permissionKey,
      orElse: () => {'description': 'Unknown permission'},
    );
    return definition['description'] as String;
  }

  /// Check if action requires authorization override
  bool requiresAuthorization(String permissionKey) {
    // These actions can be authorized by manager/supervisor even if current user doesn't have permission
    return [
      'canApplyDiscounts',
      'canVoidItemsAfterPrinting',
      'canVoidPaidTransactions',
      'canOpenCashDrawerNoSale',
      'canViewExpectedCash',
      'canAcknowledgeVariance',
      'canEditTaxSettings',
      'canExemptSST',
    ].contains(permissionKey);
  }
}
