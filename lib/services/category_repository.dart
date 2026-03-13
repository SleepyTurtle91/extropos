import 'package:extropos/models/category_model.dart' as cat_model;
import 'package:extropos/services/database_service.dart';

/// Abstraction for category data access used by UI screens. This allows a
/// small test seam for injecting fakes/mocks during widget tests.
abstract class CategoryRepository {
  Future<List<cat_model.Category>> getCategories();
  Future<cat_model.Category> createCategory(cat_model.Category category);
  Future<cat_model.Category> updateCategory(cat_model.Category category);
  Future<void> deleteCategory(String id);
}

/// Default production implementation that delegates to DatabaseService.
class DatabaseCategoryRepository implements CategoryRepository {
  final DatabaseService _db = DatabaseService.instance;

  @override
  Future<cat_model.Category> createCategory(cat_model.Category category) async {
    await _db.insertCategory(category);
    return category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
  }

  @override
  Future<List<cat_model.Category>> getCategories() async {
    final categories = await _db.getCategories();
    return categories.cast<cat_model.Category>();
  }

  @override
  Future<cat_model.Category> updateCategory(cat_model.Category category) async {
    await _db.updateCategory(category);
    return category;
  }
}
