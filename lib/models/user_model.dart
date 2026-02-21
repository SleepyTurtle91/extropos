enum UserRole { superAdmin, admin, manager, supervisor, cashier, waiter }

enum UserStatus { active, inactive, suspended }

class RolePermissions {
  // Core POS operations
  final bool canAccessPOS;
  final bool canProcessSales;
  final bool canSignInOut;

  // Transaction modifications
  final bool canApplyDiscounts;
  final bool canVoidItemsAfterPrinting;
  final bool canProcessRefunds;
  final bool canVoidPaidTransactions;

  // Cash management
  final bool canOpenCashDrawerNoSale;
  final bool canViewExpectedCash;
  final bool canPerformBlindCount;
  final bool canPerformShiftEnd;
  final bool canPerformDayClosing;
  final bool canAcknowledgeVariance;

  // SST and tax management
  final bool canEditTaxSettings;
  final bool canExemptSST;

  // Administrative
  final bool canManageUsers;
  final bool canManageItems;
  final bool canManageTables;
  final bool canViewReports;
  final bool canManageBusinessSettings;
  final bool canOpenCloseBusiness;
  final bool canManagePrinters;
  final bool canManagePaymentMethods;

  const RolePermissions({
    required this.canAccessPOS,
    required this.canProcessSales,
    required this.canSignInOut,
    required this.canApplyDiscounts,
    required this.canVoidItemsAfterPrinting,
    required this.canProcessRefunds,
    required this.canVoidPaidTransactions,
    required this.canOpenCashDrawerNoSale,
    required this.canViewExpectedCash,
    required this.canPerformBlindCount,
    required this.canPerformShiftEnd,
    required this.canPerformDayClosing,
    required this.canAcknowledgeVariance,
    required this.canEditTaxSettings,
    required this.canExemptSST,
    required this.canManageUsers,
    required this.canManageItems,
    required this.canManageTables,
    required this.canViewReports,
    required this.canManageBusinessSettings,
    required this.canOpenCloseBusiness,
    required this.canManagePrinters,
    required this.canManagePaymentMethods,
  });

  // Malaysian POS permission hierarchy
  static RolePermissions getPermissionsForRole(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const RolePermissions(
          canAccessPOS: true,
          canProcessSales: true,
          canSignInOut: true,
          canApplyDiscounts: true,
          canVoidItemsAfterPrinting: true,
          canProcessRefunds: true,
          canVoidPaidTransactions: true,
          canOpenCashDrawerNoSale: true,
          canViewExpectedCash: true,
          canPerformBlindCount: true,
          canPerformShiftEnd: true,
          canPerformDayClosing: true,
          canAcknowledgeVariance: true,
          canEditTaxSettings: true,
          canExemptSST: true,
          canManageUsers: true,
          canManageItems: true,
          canManageTables: true,
          canViewReports: true,
          canManageBusinessSettings: true,
          canOpenCloseBusiness: true,
          canManagePrinters: true,
          canManagePaymentMethods: true,
        );
      case UserRole.admin:
        return const RolePermissions(
          canAccessPOS: true,
          canProcessSales: true,
          canSignInOut: true,
          canApplyDiscounts: true,
          canVoidItemsAfterPrinting: true,
          canProcessRefunds: true,
          canVoidPaidTransactions: true,
          canOpenCashDrawerNoSale: true,
          canViewExpectedCash: true,
          canPerformBlindCount: true,
          canPerformShiftEnd: true,
          canPerformDayClosing: true,
          canAcknowledgeVariance: true,
          canEditTaxSettings: true,
          canExemptSST: true,
          canManageUsers: true,
          canManageItems: true,
          canManageTables: true,
          canViewReports: true,
          canManageBusinessSettings: true,
          canOpenCloseBusiness: true,
          canManagePrinters: true,
          canManagePaymentMethods: true,
        );
      case UserRole.manager:
        return const RolePermissions(
          canAccessPOS: true,
          canProcessSales: true,
          canSignInOut: true,
          canApplyDiscounts: true,
          canVoidItemsAfterPrinting: true,
          canProcessRefunds: true,
          canVoidPaidTransactions: true,
          canOpenCashDrawerNoSale: true,
          canViewExpectedCash:
              true, // Can view expected cash for variance reports
          canPerformBlindCount: true,
          canPerformShiftEnd: true,
          canPerformDayClosing: true, // Only managers can perform day closing
          canAcknowledgeVariance: true, // Can acknowledge cash variances
          canEditTaxSettings: true, // Can edit SST settings
          canExemptSST: true, // Can exempt SST with proper documentation
          canManageUsers: false,
          canManageItems: true,
          canManageTables: true,
          canViewReports: true,
          canManageBusinessSettings: true,
          canOpenCloseBusiness: true,
          canManagePrinters: true,
          canManagePaymentMethods: true,
        );
      case UserRole.supervisor:
        return const RolePermissions(
          canAccessPOS: true,
          canProcessSales: true,
          canSignInOut: true,
          canApplyDiscounts: true, // Can apply small discounts (e.g., 5%)
          canVoidItemsAfterPrinting:
              true, // Can void/delete items after printing
          canProcessRefunds: true,
          canVoidPaidTransactions: false, // Cannot void paid transactions
          canOpenCashDrawerNoSale: true, // Can open drawer for change/no sale
          canViewExpectedCash:
              false, // Cannot view expected cash (prevents skimming)
          canPerformBlindCount: false,
          canPerformShiftEnd: true,
          canPerformDayClosing: false, // Cannot perform day closing
          canAcknowledgeVariance: false, // Cannot acknowledge variances
          canEditTaxSettings: false, // Cannot edit tax settings
          canExemptSST: true, // Can exempt SST with documentation
          canManageUsers: false,
          canManageItems: false,
          canManageTables: true,
          canViewReports: true,
          canManageBusinessSettings: false,
          canOpenCloseBusiness: false,
          canManagePrinters: false,
          canManagePaymentMethods: false,
        );
      case UserRole.cashier:
        return const RolePermissions(
          canAccessPOS: true,
          canProcessSales: true, // Can process sales and e-wallets
          canSignInOut: true, // Can sign in/out and open shift
          canApplyDiscounts: false, // Cannot apply discounts
          canVoidItemsAfterPrinting: false, // Cannot void after printing
          canProcessRefunds: false, // Cannot process refunds
          canVoidPaidTransactions: false, // Cannot void paid transactions
          canOpenCashDrawerNoSale: false, // Cannot open drawer without sale
          canViewExpectedCash:
              false, // Cannot view expected cash (prevents skimming)
          canPerformBlindCount: true, // Can perform blind count
          canPerformShiftEnd: true, // Can perform shift end (X-Report)
          canPerformDayClosing: false, // Cannot perform day closing
          canAcknowledgeVariance: false, // Cannot acknowledge variances
          canEditTaxSettings: false, // Cannot edit tax settings
          canExemptSST: false, // Cannot exempt SST
          canManageUsers: false,
          canManageItems: false,
          canManageTables: false,
          canViewReports: false,
          canManageBusinessSettings: false,
          canOpenCloseBusiness: false,
          canManagePrinters: false,
          canManagePaymentMethods: false,
        );
      case UserRole.waiter:
        return const RolePermissions(
          canAccessPOS: true,
          canProcessSales: false, // Waiters typically don't process payments
          canSignInOut: true,
          canApplyDiscounts: false,
          canVoidItemsAfterPrinting: false,
          canProcessRefunds: false,
          canVoidPaidTransactions: false,
          canOpenCashDrawerNoSale: false,
          canViewExpectedCash: false,
          canPerformBlindCount: false,
          canPerformShiftEnd: false,
          canPerformDayClosing: false,
          canAcknowledgeVariance: false,
          canEditTaxSettings: false,
          canExemptSST: false,
          canManageUsers: false,
          canManageItems: false,
          canManageTables: true, // Can manage table status
          canViewReports: false,
          canManageBusinessSettings: false,
          canOpenCloseBusiness: false,
          canManagePrinters: false,
          canManagePaymentMethods: false,
        );
    }
  }

  // Get permission descriptions for UI
  static List<Map<String, dynamic>> getPermissionDefinitions() {
    return [
      {
        'key': 'canAccessPOS',
        'title': 'Access POS System',
        'description': 'Can use the Point of Sale interface',
      },
      {
        'key': 'canProcessSales',
        'title': 'Process Sales',
        'description': 'Can process sales transactions and e-wallet payments',
      },
      {
        'key': 'canSignInOut',
        'title': 'Sign In/Out',
        'description': 'Can sign in/out and manage shifts',
      },
      {
        'key': 'canApplyDiscounts',
        'title': 'Apply Discounts',
        'description': 'Can apply discounts to transactions',
      },
      {
        'key': 'canVoidItemsAfterPrinting',
        'title': 'Void Items After Printing',
        'description':
            'Can void/delete items after kitchen/receipt has been printed',
      },
      {
        'key': 'canProcessRefunds',
        'title': 'Process Refunds',
        'description': 'Can process customer refunds',
      },
      {
        'key': 'canVoidPaidTransactions',
        'title': 'Void Paid Transactions',
        'description': 'Can void transactions that have already been paid',
      },
      {
        'key': 'canOpenCashDrawerNoSale',
        'title': 'Open Cash Drawer (No Sale)',
        'description':
            'Can open cash drawer without a sale (e.g., to give change)',
      },
      {
        'key': 'canViewExpectedCash',
        'title': 'View Expected Cash',
        'description': 'Can view the expected cash amount before blind count',
      },
      {
        'key': 'canPerformBlindCount',
        'title': 'Perform Blind Count',
        'description': 'Can perform cash drawer blind count',
      },
      {
        'key': 'canPerformShiftEnd',
        'title': 'Perform Shift End (X-Report)',
        'description': 'Can end shift and generate X-Report',
      },
      {
        'key': 'canPerformDayClosing',
        'title': 'Perform Day Closing (Z-Report)',
        'description': 'Can perform day closing and generate Z-Report',
      },
      {
        'key': 'canAcknowledgeVariance',
        'title': 'Acknowledge Cash Variance',
        'description': 'Can acknowledge and resolve cash count variances',
      },
      {
        'key': 'canEditTaxSettings',
        'title': 'Edit Tax/SST Settings',
        'description': 'Can modify tax rates and SST settings',
      },
      {
        'key': 'canExemptSST',
        'title': 'Exempt SST',
        'description': 'Can apply SST exemptions with proper documentation',
      },
      {
        'key': 'canManageUsers',
        'title': 'Manage Users',
        'description': 'Can add, edit, and delete user accounts',
      },
      {
        'key': 'canManageItems',
        'title': 'Manage Items',
        'description': 'Can add, edit, and delete menu items',
      },
      {
        'key': 'canManageTables',
        'title': 'Manage Tables',
        'description': 'Can manage restaurant tables and reservations',
      },
      {
        'key': 'canViewReports',
        'title': 'View Reports',
        'description': 'Can access sales and analytics reports',
      },
      {
        'key': 'canManageBusinessSettings',
        'title': 'Manage Business Settings',
        'description': 'Can modify business information and settings',
      },
      {
        'key': 'canOpenCloseBusiness',
        'title': 'Open/Close Business',
        'description': 'Can open and close the business for the day',
      },
      {
        'key': 'canManagePrinters',
        'title': 'Manage Printers',
        'description': 'Can configure receipt and kitchen printers',
      },
      {
        'key': 'canManagePaymentMethods',
        'title': 'Manage Payment Methods',
        'description': 'Can add and configure payment methods',
      },
    ];
  }
}

class User {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final UserRole role;
  UserStatus status;
  final String pin;
  DateTime? lastLoginAt;
  DateTime createdAt;
  String? phoneNumber;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    required this.pin,
    this.status = UserStatus.active,
    this.lastLoginAt,
    DateTime? createdAt,
    this.phoneNumber,
  }) : createdAt = createdAt ?? DateTime.now();

  String get roleDisplayName {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Administrator';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.manager:
        return 'Manager';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.cashier:
        return 'Cashier';
      case UserRole.waiter:
        return 'Waiter';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.suspended:
        return 'Suspended';
    }
  }

  RolePermissions get permissions =>
      RolePermissions.getPermissionsForRole(role);

  // Legacy permission getters for backward compatibility
  bool get canManageUsers => permissions.canManageUsers;
  bool get canManageSettings => permissions.canManageBusinessSettings;
  bool get canViewReports => permissions.canViewReports;
  bool get canProcessPayments => permissions.canAccessPOS;

  User copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    UserRole? role,
    UserStatus? status,
    String? pin,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    String? phoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      pin: pin ?? this.pin,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
