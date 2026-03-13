/// SQL schema definitions for the multi-tenant / dealer domain.
/// Pure Dart, no Flutter imports — fully unit testable.
abstract final class TenantSchema {
  // ─── Tables ───────────────────────────────────────────────────────────────

  static const String createDealerCustomersTable = '''
    CREATE TABLE dealer_customers (
      id TEXT PRIMARY KEY,
      business_name TEXT NOT NULL,
      owner_name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      phone TEXT NOT NULL,
      address TEXT NOT NULL,
      city TEXT NOT NULL,
      state TEXT NOT NULL,
      postcode TEXT NOT NULL,
      country TEXT DEFAULT 'Malaysia',
      registration_number TEXT,
      tax_number TEXT,
      website TEXT,
      is_active INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String createTenantsTable = '''
    CREATE TABLE tenants (
      id TEXT PRIMARY KEY,
      customer_id TEXT NOT NULL,
      tenant_name TEXT NOT NULL,
      owner_name TEXT NOT NULL,
      owner_email TEXT NOT NULL,
      custom_domain TEXT,
      api_key TEXT,
      is_active INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES dealer_customers (id) ON DELETE CASCADE
    )
  ''';

  // ─── Indexes ──────────────────────────────────────────────────────────────

  static const List<String> indexes = [
    'CREATE INDEX idx_dealer_customers_email ON dealer_customers(email)',
    'CREATE INDEX idx_dealer_customers_business_name ON dealer_customers(business_name)',
    'CREATE INDEX idx_dealer_customers_active ON dealer_customers(is_active)',
    'CREATE INDEX idx_tenants_customer_id ON tenants(customer_id)',
    'CREATE INDEX idx_tenants_owner_email ON tenants(owner_email)',
    'CREATE INDEX idx_tenants_active ON tenants(is_active)',
  ];

  // ─── All tables in creation order (FK dependencies respected) ─────────────

  static const List<String> allTables = [
    createDealerCustomersTable,
    createTenantsTable,
  ];
}
