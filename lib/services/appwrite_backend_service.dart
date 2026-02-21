import 'dart:developer' as developer;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:extropos/config/environment.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/modifier_group_model.dart';
import 'package:extropos/models/modifier_item_model.dart';
import 'package:flutter/material.dart';

/// Helper class to store BusinessInfo with its Appwrite document ID
class BusinessInfoWithId {
  final String id;
  final BusinessInfo businessInfo;

  BusinessInfoWithId({required this.id, required this.businessInfo});
}

/// Appwrite service for Backend flavor operations
/// Handles CRUD operations for categories, items, modifiers, and business settings
class AppwriteBackendService {
  static final AppwriteBackendService instance =
      AppwriteBackendService._internal();
  AppwriteBackendService._internal();

  Client? _client;
  Databases? _databases;
  Storage? _storage;
  bool _isInitialized = false;

  // Initialize Appwrite client
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _client = Client()
          .setEndpoint(Environment.appwritePublicEndpoint)
          .setProject(Environment.appwriteProjectId);

      _databases = Databases(_client!);
      _storage = Storage(_client!);
      _isInitialized = true;

      developer.log('AppwriteBackendService: Initialized successfully');
    } catch (e) {
      developer.log('AppwriteBackendService: Initialization failed: $e');
      rethrow;
    }
  }

  // Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // ==================== CATEGORIES ====================

  /// Get all categories
  Future<List<Category>> getCategories() async {
    await _ensureInitialized();
    try {
      final result = await _databases!.listDocuments(
        databaseId: Environment.posDatabase,
        collectionId: Environment.categoriesCollection,
        queries: [
          Query.equal('is_active', true),
          Query.orderAsc('sort_order'),
          Query.orderAsc('name'),
        ],
      );

      return result.documents.map((doc) => _categoryFromDocument(doc)).toList();
    } catch (e) {
      developer.log('AppwriteBackendService: getCategories failed: $e');
      rethrow;
    }
  }

  /// Create a new category
  Future<Category> createCategory(Category category) async {
    await _ensureInitialized();
    try {
      final doc = await _databases!.createDocument(
        databaseId: Environment.posDatabase,
        collectionId: Environment.categoriesCollection,
        documentId: ID.unique(),
        data: {
          'name': category.name,
          'description': category.description,
          'sort_order': category.sortOrder,
          'is_active': category.isActive,
          'icon_code_point': category.icon.codePoint,
          'icon_font_family': category.icon.fontFamily,
          'color_value': category.color.value,
        },
      );

      return _categoryFromDocument(doc);
    } catch (e) {
      developer.log('AppwriteBackendService: createCategory failed: $e');
      rethrow;
    }
  }

  /// Update an existing category
  Future<Category> updateCategory(String id, Category category) async {
    await _ensureInitialized();
    try {
      final doc = await _databases!.updateDocument(
        databaseId: Environment.posDatabase,
        collectionId: Environment.categoriesCollection,
        documentId: id,
        data: {
          'name': category.name,
          'description': category.description,
          'sort_order': category.sortOrder,
          'is_active': category.isActive,
          'icon_code_point': category.icon.codePoint,
          'icon_font_family': category.icon.fontFamily,
          'color_value': category.color.value,
        },
      );

      return _categoryFromDocument(doc);
    } catch (e) {
      developer.log('AppwriteBackendService: updateCategory failed: $e');
      rethrow;
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    await _ensureInitialized();
    try {
      await _databases!.deleteDocument(
        databaseId: Environment.posDatabase,
        collectionId: Environment.categoriesCollection,
        documentId: id,
      );
    } catch (e) {
      developer.log('AppwriteBackendService: deleteCategory failed: $e');
      rethrow;
    }
  }

  // ==================== ITEMS (PRODUCTS) ====================

  /// Get all items
  Future<List<Item>> getItems() async {
    await _ensureInitialized();
    try {
      final result = await _databases!.listDocuments(
        databaseId: Environment.posDatabase,
        collectionId: Environment.itemsCollection,
        queries: [Query.equal('is_available', true), Query.orderAsc('name')],
      );

      return result.documents.map((doc) => _itemFromDocument(doc)).toList();
    } catch (e) {
      developer.log('AppwriteBackendService: getItems failed: $e');
      rethrow;
    }
  }

  /// Create a new item
  Future<Item> createItem(Item item) async {
    await _ensureInitialized();
    try {
      final doc = await _databases!.createDocument(
        databaseId: Environment.posDatabase,
        collectionId: Environment.itemsCollection,
        documentId: ID.unique(),
        data: {
          'name': item.name,
          'description': item.description,
          'price': item.price,
          'category_id': item.categoryId,
          'image_url': item.imageUrl,
          'stock': item.stock,
          'is_available': item.isAvailable,
          'barcode': item.barcode,
          'sku': item.sku,
        },
      );

      return _itemFromDocument(doc);
    } catch (e) {
      developer.log('AppwriteBackendService: createItem failed: $e');
      rethrow;
    }
  }

  /// Update an existing item
  Future<Item> updateItem(String id, Item item) async {
    await _ensureInitialized();
    try {
      final doc = await _databases!.updateDocument(
        databaseId: Environment.posDatabase,
        collectionId: Environment.itemsCollection,
        documentId: id,
        data: {
          'name': item.name,
          'description': item.description,
          'price': item.price,
          'category_id': item.categoryId,
          'image_url': item.imageUrl,
          'stock': item.stock,
          'is_available': item.isAvailable,
          'barcode': item.barcode,
          'sku': item.sku,
        },
      );

      return _itemFromDocument(doc);
    } catch (e) {
      developer.log('AppwriteBackendService: updateItem failed: $e');
      rethrow;
    }
  }

  /// Delete an item
  Future<void> deleteItem(String id) async {
    await _ensureInitialized();
    try {
      await _databases!.deleteDocument(
        databaseId: Environment.posDatabase,
        collectionId: Environment.itemsCollection,
        documentId: id,
      );
    } catch (e) {
      developer.log('AppwriteBackendService: deleteItem failed: $e');
      rethrow;
    }
  }

  // ==================== MODIFIERS ====================

  /// Get all modifier groups
  Future<List<ModifierGroup>> getModifierGroups() async {
    await _ensureInitialized();
    try {
      final result = await _databases!.listDocuments(
        databaseId: Environment.posDatabase,
        collectionId: 'modifier_groups',
        queries: [Query.orderAsc('name')],
      );

      return result.documents
          .map((doc) => _modifierGroupFromDocument(doc))
          .toList();
    } catch (e) {
      developer.log('AppwriteBackendService: getModifierGroups failed: $e');
      rethrow;
    }
  }

  /// Get modifier groups for a specific category
  Future<List<ModifierGroup>> getModifierGroupsForCategory(
    String categoryId,
  ) async {
    await _ensureInitialized();
    try {
      final result = await _databases!.listDocuments(
        databaseId: Environment.posDatabase,
        collectionId: 'modifier_groups',
        queries: [
          Query.equal('category_ids', categoryId),
          Query.orderAsc('sort_order'),
        ],
      );

      return result.documents
          .map((doc) => _modifierGroupFromDocument(doc))
          .toList();
    } catch (e) {
      developer.log(
        'AppwriteBackendService: getModifierGroupsForCategory failed: $e',
      );
      rethrow;
    }
  }

  /// Get modifier items for a specific group
  Future<List<ModifierItem>> getModifierItems(String groupId) async {
    await _ensureInitialized();
    try {
      final result = await _databases!.listDocuments(
        databaseId: Environment.posDatabase,
        collectionId: 'modifier_items',
        queries: [
          Query.equal('modifier_group_id', groupId),
          Query.equal('is_available', true),
          Query.orderAsc('sort_order'),
        ],
      );

      return result.documents
          .map((doc) => _modifierItemFromDocument(doc))
          .toList();
    } catch (e) {
      developer.log('AppwriteBackendService: getModifierItems failed: $e');
      rethrow;
    }
  }

  /// Update a modifier group
  Future<ModifierGroup> updateModifierGroup(
    String id,
    ModifierGroup group,
  ) async {
    await _ensureInitialized();
    try {
      final doc = await _databases!.updateDocument(
        databaseId: Environment.posDatabase,
        collectionId: 'modifier_groups',
        documentId: id,
        data: {
          'name': group.name,
          'description': group.description,
          'min_selections': group.minSelection,
          'max_selections': group.maxSelection,
          'is_required': group.isRequired,
        },
      );

      return _modifierGroupFromDocument(doc);
    } catch (e) {
      developer.log('AppwriteBackendService: updateModifierGroup failed: $e');
      rethrow;
    }
  }

  /// Delete a modifier group
  Future<void> deleteModifierGroup(String id) async {
    await _ensureInitialized();
    try {
      await _databases!.deleteDocument(
        databaseId: Environment.posDatabase,
        collectionId: 'modifier_groups',
        documentId: id,
      );
    } catch (e) {
      developer.log('AppwriteBackendService: deleteModifierGroup failed: $e');
      rethrow;
    }
  }

  // ==================== BUSINESS INFO ====================

  /// Get business info
  Future<BusinessInfoWithId?> getBusinessInfo() async {
    await _ensureInitialized();
    try {
      final result = await _databases!.listDocuments(
        databaseId: Environment.posDatabase,
        collectionId: 'business_info',
        queries: [Query.limit(1)],
      );

      if (result.documents.isEmpty) return null;
      final doc = result.documents.first;
      return BusinessInfoWithId(
        id: doc.$id,
        businessInfo: _businessInfoFromDocument(doc),
      );
    } catch (e) {
      developer.log('AppwriteBackendService: getBusinessInfo failed: $e');
      rethrow;
    }
  }

  /// Update business info
  Future<BusinessInfo> updateBusinessInfo(BusinessInfo info) async {
    await _ensureInitialized();
    try {
      // Try to get existing document first
      final existing = await getBusinessInfo();

      if (existing != null) {
        // Update existing
        final doc = await _databases!.updateDocument(
          databaseId: Environment.posDatabase,
          collectionId: 'business_info',
          documentId: existing.id,
          data: _businessInfoToData(info),
        );
        return _businessInfoFromDocument(doc);
      } else {
        // Create new
        final doc = await _databases!.createDocument(
          databaseId: Environment.posDatabase,
          collectionId: 'business_info',
          documentId: ID.unique(),
          data: _businessInfoToData(info),
        );
        return _businessInfoFromDocument(doc);
      }
    } catch (e) {
      developer.log('AppwriteBackendService: updateBusinessInfo failed: $e');
      rethrow;
    }
  }

  // ==================== FILE UPLOAD ====================

  /// Upload product image
  Future<String> uploadProductImage(String filePath, String fileName) async {
    await _ensureInitialized();
    try {
      final file = await _storage!.createFile(
        bucketId: 'product_images',
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath, filename: fileName),
      );

      // Return the file URL
      return _storage!
          .getFileView(bucketId: 'product_images', fileId: file.$id)
          .toString();
    } catch (e) {
      developer.log('AppwriteBackendService: uploadProductImage failed: $e');
      rethrow;
    }
  }

  /// Upload logo image
  Future<String> uploadLogoImage(String filePath, String fileName) async {
    await _ensureInitialized();
    try {
      final file = await _storage!.createFile(
        bucketId: 'logo_images',
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath, filename: fileName),
      );

      return _storage!
          .getFileView(bucketId: 'logo_images', fileId: file.$id)
          .toString();
    } catch (e) {
      developer.log('AppwriteBackendService: uploadLogoImage failed: $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  Category _categoryFromDocument(Document doc) {
    return Category(
      id: doc.$id,
      name: doc.data['name'] ?? '',
      description: doc.data['description'] ?? '',
      icon:
          _iconFromData(
            doc.data['icon_code_point'],
            doc.data['icon_font_family'],
          ) ??
          Icons.category,
      color: _colorFromData(doc.data['color_value']) ?? Colors.blue,
      sortOrder: doc.data['sort_order'] ?? 0,
      isActive: doc.data['is_active'] ?? true,
    );
  }

  Item _itemFromDocument(Document doc) {
    return Item(
      id: doc.$id,
      name: doc.data['name'] ?? '',
      description: doc.data['description'] ?? '',
      price: (doc.data['price'] ?? 0.0).toDouble(),
      categoryId: doc.data['category_id'] ?? '',
      sku: doc.data['sku'],
      barcode: doc.data['barcode'],
      icon: Icons.restaurant, // Default icon
      color: Colors.blue, // Default color
      stock: doc.data['stock'] ?? 0,
      isAvailable: doc.data['is_available'] ?? true,
      imageUrl: doc.data['image_url'],
    );
  }

  ModifierGroup _modifierGroupFromDocument(Document doc) {
    return ModifierGroup(
      id: doc.$id,
      name: doc.data['name'] ?? '',
      description: doc.data['description'] ?? '',
      categoryIds: List<String>.from(doc.data['category_ids'] ?? []),
      minSelection: doc.data['min_selections'],
      maxSelection: doc.data['max_selections'],
      isRequired: doc.data['is_required'] ?? false,
      allowMultiple: doc.data['allow_multiple'] ?? false,
      sortOrder: doc.data['sort_order'] ?? 0,
      isActive: doc.data['is_active'] ?? true,
    );
  }

  ModifierItem _modifierItemFromDocument(Document doc) {
    return ModifierItem(
      id: doc.$id,
      modifierGroupId: doc.data['modifier_group_id'] ?? '',
      name: doc.data['name'] ?? '',
      description: doc.data['description'] ?? '',
      priceAdjustment: (doc.data['price_adjustment'] ?? 0.0).toDouble(),
      icon: _iconFromData(
        doc.data['icon_code_point'],
        doc.data['icon_font_family'],
      ),
      color: _colorFromData(doc.data['color_value']),
      isDefault: doc.data['is_default'] ?? false,
      isAvailable: doc.data['is_available'] ?? true,
      sortOrder: doc.data['sort_order'] ?? 0,
    );
  }

  BusinessInfo _businessInfoFromDocument(Document doc) {
    return BusinessInfo(
      businessName: doc.data['business_name'] ?? '',
      ownerName: doc.data['owner_name'] ?? '',
      email: doc.data['email'] ?? '',
      phone: doc.data['phone'] ?? '',
      address: doc.data['address'] ?? '',
      city: doc.data['city'] ?? '',
      state: doc.data['state'] ?? '',
      postcode: doc.data['postcode'] ?? '',
      taxNumber: doc.data['tax_number'] ?? '',
      currencySymbol: doc.data['currency_symbol'] ?? 'RM',
      isTaxEnabled: doc.data['is_tax_enabled'] ?? false,
      taxRate: (doc.data['tax_rate'] ?? 0.0).toDouble(),
      isServiceChargeEnabled: doc.data['is_service_charge_enabled'] ?? false,
      serviceChargeRate: (doc.data['service_charge_rate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> _businessInfoToData(BusinessInfo info) {
    return {
      'business_name': info.businessName,
      'owner_name': info.ownerName,
      'email': info.email,
      'phone': info.phone,
      'address': info.address,
      'city': info.city,
      'state': info.state,
      'postcode': info.postcode,
      'tax_number': info.taxNumber,
      'currency_symbol': info.currencySymbol,
      'is_tax_enabled': info.isTaxEnabled,
      'tax_rate': info.taxRate,
      'is_service_charge_enabled': info.isServiceChargeEnabled,
      'service_charge_rate': info.serviceChargeRate,
    };
  }

  IconData? _iconFromData(int? codePoint, String? fontFamily) {
    // For web backend, return a constant icon to avoid tree-shaking issues
    return Icons.category; // Return constant icon instead of dynamic IconData
  }

  Color? _colorFromData(int? value) {
    if (value == null) return null;
    return Color(value);
  }
}
