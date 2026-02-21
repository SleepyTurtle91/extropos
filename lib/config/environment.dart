class Environment {
  // Local Appwrite Docker instance
  static const String appwriteProjectId = 'default';
  static const String appwriteProjectName = 'FlutterPOS';

  // API Key for server-side operations (database/bucket setup)
  // Can be overridden at build/run time with: --dart-define=APPWRITE_API_KEY=... (preferred for secrets)
  static const String appwriteApiKey = String.fromEnvironment(
    'APPWRITE_API_KEY',
    defaultValue:
        '3764ecef9f9b79c417206e26a4a96408a7e4a70c07e3ed11383f0a67dc9d7fccef8f3144491d34cbccca49dab4021164df6c441a998d38cd6e03b4e6b55a865e97af44042487f34ed508cc56a2b50b36a0eac1779d979a6d5ab606bfee9b58ac05f9833528eb9bb0a6a97839186d7a96d8b0a9bc6c20477bd47f7f3e222c3792',
  );

  // Appwrite endpoint; override with --dart-define=APPWRITE_ENDPOINT=http://localhost:8080/v1 for local dev
  static const String appwritePublicEndpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://appwrite.extropos.org/v1',
  );

  // Appwrite Database and Collection IDs
  static const String posDatabase = 'pos_db';
  static const String categoriesCollection = 'categories';
  static const String itemsCollection = 'items';
  static const String ordersCollection = 'orders';
  static const String orderItemsCollection = 'order_items';
  static const String usersCollection = 'users';
  static const String tablesCollection = 'tables';
  static const String paymentMethodsCollection = 'payment_methods';
  static const String customersCollection = 'customers';
  static const String transactionsCollection = 'transactions';
  static const String printersCollection = 'printers';
  static const String customerDisplaysCollection = 'customer_displays';
  static const String receiptSettingsCollection = 'receipt_settings';
  static const String modifierGroupsCollection = 'modifier_groups';
  static const String modifierItemsCollection = 'modifier_items';
  static const String businessInfoCollection = 'business_info';
  static const String licensesCollection = 'licenses';

  // Appwrite Bucket IDs
  static const String receiptImagesBucket = 'receipt_images';
  static const String productImagesBucket = 'product_images';
  static const String logoImagesBucket = 'logo_images';
  static const String reportsBucket = 'reports';
}
