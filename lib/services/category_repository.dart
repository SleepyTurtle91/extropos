import 'package:extropos/models/category_model.dart';
import 'package:extropos/services/database_service.dart';

/// Abstraction for category data access used by UI screens. This allows a
/// small test seam for injecting fakes/mocks during widget tests.
abstract class CategoryRepository {
  Future<List<Category>> getCategories();
  Future<Category> createCategory(Category category);
  Future<Category> updateCategory(Category category);
  Future<void> deleteCategory(String id);
}

/// Default production implementation that delegates to DatabaseService.
class DatabaseCategoryRepository implements CategoryRepository {
  final DatabaseService _db = DatabaseService.instance;

  @override
  Future<Category> createCategory(Category category) async {
    await _db.insertCategory(category);
    return category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
  }

  @override
  Future<List<Category>> getCategories() async {
    return _db.getCategories();
  }

  @override
  Future<Category> updateCategory(Category category) async {
    await _db.updateCategory(category);
    return category;
  }
}
