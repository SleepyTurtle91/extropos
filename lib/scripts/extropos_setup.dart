import 'package:extropos/migrations/pos_products_migration.dart';
import 'package:extropos/repositories/product_repository.dart';
import 'package:extropos/seeders/pos_product_seeder.dart';

/// Quick setup script for ExtroPOS database integration
/// 
/// Run this once to:
/// 1. Create pos_products table
/// 2. Seed sample data for all modes
/// 3. Verify setup
/// 
/// Usage:
/// ```dart
/// import 'package:extropos/scripts/extropos_setup.dart';
/// 
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await ExtroPOSSetup.runSetup();
///   runApp(const MyApp());
/// }
/// ```
class ExtroPOSSetup {
  static Future<void> runSetup({bool seedData = true}) async {
    try {
      print('🚀 ExtroPOS Database Setup Starting...\n');

      // Step 1: Check if table exists
      print('📋 Step 1: Checking database...');
      final tableExists = await POSProductsMigration.isTableExists();
      
      if (tableExists) {
        print('✅ pos_products table already exists');
      } else {
        print('🔄 Creating pos_products table...');
        await POSProductsMigration.migrate();
      }

      // Step 2: Seed data if requested
      if (seedData) {
        print('\n📋 Step 2: Seeding sample data...');
        final repository = DatabaseProductRepository();
        final seeder = POSProductSeeder(repository);
        await seeder.seedAll();
      }

      // Step 3: Verify setup
      print('\n📋 Step 3: Verifying setup...');
      final repository = DatabaseProductRepository();
      
      final retailProducts = await repository.getProducts(mode: 'retail');
      final cafeProducts = await repository.getProducts(mode: 'cafe');
      final restaurantProducts = await repository.getProducts(mode: 'restaurant');
      
      print('✅ Retail mode: ${retailProducts.length} products');
      print('✅ Cafe mode: ${cafeProducts.length} products');
      print('✅ Restaurant mode: ${restaurantProducts.length} products');

      print('\n🎉 Setup Complete! ExtroPOS is ready to use.\n');
    } catch (e) {
      print('\n❌ Setup failed: $e');
      print('Please check the error and try again.\n');
      rethrow;
    }
  }

  /// Clear all products (useful for testing)
  static Future<void> clearAllProducts() async {
    try {
      print('🗑️ Clearing all products...');
      final repository = DatabaseProductRepository();
      
      final allProducts = await repository.getProducts();
      for (final product in allProducts) {
        await repository.deleteProduct(product.id);
      }
      
      print('✅ All products cleared');
    } catch (e) {
      print('❌ Error clearing products: $e');
      rethrow;
    }
  }

  /// Re-seed data (clears existing and seeds fresh)
  static Future<void> reseedData() async {
    await clearAllProducts();
    await runSetup(seedData: true);
  }
}
