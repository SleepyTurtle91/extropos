part of 'retail_pos_screen.dart';

extension RetailPOSDataOps on _RetailPOSScreenState {
  Future<void> _checkShiftStatus() async {
    final user = LockManager.instance.currentUser;
    if (user == null) return;

    await ShiftService().initialize(user.id);

    // TODO: Implement shift management dialog
    // if (!ShiftService().hasActiveShift && mounted) {
    //   final started = await showDialog<bool>(
    //     context: context,
    //     barrierDismissible: false,
    //     builder: (context) => StartShiftDialog(userId: user.id),
    //   );

    //   if (started != true && mounted) {
    //     ToastHelper.showToast(context, 'You must start a shift to process orders');
    //   }
    // }
  }

  Future<void> _loadFromDatabase() async {
    try {
      final List<Category> dbCategories = await DatabaseService.instance.getCategories();
      final List<Item> dbItems = await DatabaseService.instance.getItems();

      if (dbCategories.isNotEmpty) {
        final List<String> newCategories = ['All', ...dbCategories.map((c) => c.name)];
        if (mounted) {
          _updateState(() {
            categories = newCategories;
            _categoryObjects = dbCategories;
            if (!categories.contains(selectedCategory)) {
              selectedCategory = 'All';
            }
          });
        }
      }

      if (dbItems.isNotEmpty) {
        final Map<String, Category> catById = {for (final c in dbCategories) c.id: c};
        final List<Product> newProducts = dbItems.map((it) {
          final catName = catById[it.categoryId]?.name ?? 'Uncategorized';
          return Product(
            it.name,
            it.price,
            catName,
            it.icon,
            id: it.id,
            imagePath: it.imageUrl,
            printerOverride: it.printerOverride,
          );
        }).toList();
        if (mounted) {
          _updateState(() {
            products = newProducts;
            _productFilterCache.clear();
          });
        }
      }
    } catch (e) {
      developer.log('Failed to load categories/items from DB: $e');
      await _ensureSampleDataInDatabase();
      if (mounted) {
        _updateState(() {
          categories = ['All', 'Food', 'Drinks', 'Desserts'];
          products = _getSampleProducts();
        });
      }
    }

    if (products.isEmpty && mounted) {
      await _ensureSampleDataInDatabase();
      _updateState(() {
        categories = ['All', 'Food', 'Drinks', 'Desserts'];
        products = _getSampleProducts();
      });
    }
  }

  List<Product> _getSampleProducts() {
    return [
      Product(
        'Pizza',
        15.00,
        'Food',
        Icons.local_pizza,
        id: 'pizza',
        variants: [
          ProductVariant(id: 'pizza_small', name: 'Small (8")', priceModifier: -5.00),
          ProductVariant(id: 'pizza_medium', name: 'Medium (12")', priceModifier: 0.00),
          ProductVariant(id: 'pizza_large', name: 'Large (16")', priceModifier: 8.00),
        ],
      ),
      Product(
        'Burger',
        12.00,
        'Food',
        Icons.lunch_dining,
        id: 'burger',
        variants: [
          ProductVariant(id: 'burger_single', name: 'Single Patty', priceModifier: 0.00),
          ProductVariant(id: 'burger_double', name: 'Double Patty', priceModifier: 5.00),
        ],
      ),
      Product(
        'Coffee',
        5.00,
        'Drinks',
        Icons.local_cafe,
        id: 'coffee',
        variants: [
          ProductVariant(id: 'coffee_small', name: 'Small', priceModifier: -1.00),
          ProductVariant(id: 'coffee_medium', name: 'Medium', priceModifier: 0.00),
          ProductVariant(id: 'coffee_large', name: 'Large', priceModifier: 1.00),
        ],
      ),
      Product('Pasta', 18.00, 'Food', Icons.restaurant, id: 'pasta'),
      Product('Salad', 10.00, 'Food', Icons.grass, id: 'salad'),
      Product('Soda', 3.00, 'Drinks', Icons.local_drink, id: 'soda'),
      Product('Ice Cream', 6.00, 'Desserts', Icons.icecream, id: 'ice_cream'),
      Product('Cake', 8.00, 'Desserts', Icons.cake, id: 'cake'),
    ];
  }

  Future<void> _ensureSampleDataInDatabase() async {
    try {
      final existingCategories = await DatabaseService.instance.getCategories();
      if (existingCategories.isEmpty) {
        final sampleCategories = [
          Category(
            id: 'sample_cat_food',
            name: 'Food',
            description: 'Meals and main dishes',
            icon: Icons.restaurant,
            color: Colors.orange,
            sortOrder: 1,
            isActive: true,
          ),
          Category(
            id: 'sample_cat_drinks',
            name: 'Drinks',
            description: 'Beverages and drinks',
            icon: Icons.local_cafe,
            color: Colors.blue,
            sortOrder: 2,
            isActive: true,
          ),
          Category(
            id: 'sample_cat_desserts',
            name: 'Desserts',
            description: 'Sweet treats and desserts',
            icon: Icons.cake,
            color: Colors.pink,
            sortOrder: 3,
            isActive: true,
          ),
        ];

        for (final category in sampleCategories) {
          try {
            await DatabaseService.instance.insertCategory(category);
          } catch (e) {
            developer.log('Failed to insert sample category ${category.name}: $e');
          }
        }
      }

      final existingItems = await DatabaseService.instance.getItems();
      if (existingItems.isEmpty) {
        final categoryData = await DatabaseService.instance.getCategories();
        final categoryMap = {for (final cat in categoryData) cat.name: cat};

        final sampleItems = [
          Item(
            id: 'sample_item_pizza',
            name: 'Pizza',
            description: 'Delicious pizza with various toppings',
            price: 15.00,
            categoryId: categoryMap['Food']?.id ?? 'sample_cat_food',
            icon: Icons.local_pizza,
            color: Colors.orange,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 1,
          ),
          Item(
            id: 'sample_item_burger',
            name: 'Burger',
            description: 'Juicy burger with fresh ingredients',
            price: 12.00,
            categoryId: categoryMap['Food']?.id ?? 'sample_cat_food',
            icon: Icons.lunch_dining,
            color: Colors.brown,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 2,
          ),
          Item(
            id: 'sample_item_coffee',
            name: 'Coffee',
            description: 'Freshly brewed coffee',
            price: 5.00,
            categoryId: categoryMap['Drinks']?.id ?? 'sample_cat_drinks',
            icon: Icons.local_cafe,
            color: Colors.brown,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 3,
          ),
          Item(
            id: 'sample_item_pasta',
            name: 'Pasta',
            description: 'Authentic pasta dish',
            price: 18.00,
            categoryId: categoryMap['Food']?.id ?? 'sample_cat_food',
            icon: Icons.restaurant,
            color: Colors.red,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 4,
          ),
          Item(
            id: 'sample_item_salad',
            name: 'Salad',
            description: 'Fresh garden salad',
            price: 10.00,
            categoryId: categoryMap['Food']?.id ?? 'sample_cat_food',
            icon: Icons.grass,
            color: Colors.green,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 5,
          ),
          Item(
            id: 'sample_item_soda',
            name: 'Soda',
            description: 'Refreshing carbonated drink',
            price: 3.00,
            categoryId: categoryMap['Drinks']?.id ?? 'sample_cat_drinks',
            icon: Icons.local_drink,
            color: Colors.blue,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 6,
          ),
          Item(
            id: 'sample_item_ice_cream',
            name: 'Ice Cream',
            description: 'Creamy ice cream dessert',
            price: 6.00,
            categoryId: categoryMap['Desserts']?.id ?? 'sample_cat_desserts',
            icon: Icons.icecream,
            color: Colors.pink,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 7,
          ),
          Item(
            id: 'sample_item_cake',
            name: 'Cake',
            description: 'Delicious cake slice',
            price: 8.00,
            categoryId: categoryMap['Desserts']?.id ?? 'sample_cat_desserts',
            icon: Icons.cake,
            color: Colors.purple,
            isAvailable: true,
            trackStock: false,
            stock: 0,
            sortOrder: 8,
          ),
        ];

        for (final item in sampleItems) {
          try {
            await DatabaseService.instance.insertItem(item);
          } catch (e) {
            developer.log('Failed to insert sample item ${item.name}: $e');
          }
        }
      }
    } catch (e) {
      developer.log('Failed to ensure sample data in database: $e');
    }
  }

  void _onBusinessInfoChanged() {
    _updateState(() {});
  }

  List<Product> _getFilteredProductsSync(String category) {
    if (_productFilterCache.containsKey(category)) {
      if (kDebugMode) {
        developer.log('RETAIL POS: cache hit for $category', name: 'retail_pos_perf');
      }
      return _productFilterCache[category]!;
    }

    final sw = Stopwatch()..start();
    final res = category == 'All'
        ? List<Product>.from(products)
        : products.where((p) => p.category == category).toList();
    sw.stop();

    if (kDebugMode) {
      developer.log(
        'RETAIL POS: computed filter for $category count=${res.length} elapsed=${sw.elapsedMilliseconds}ms',
        name: 'retail_pos_perf',
      );
    }

    _productFilterCache[category] = res;
    return res;
  }

  void _onCategorySelected(String category) {
    if (selectedCategory == category) return;
    if (kDebugMode) {
      developer.log('RETAIL POS: category selected (debounced) $category', name: 'retail_pos_perf');
    }
    _categoryDebounceTimer?.cancel();
    _categoryDebounceTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _updateState(() {
        selectedCategory = category;
      });
    });
  }

  Future<void> _updateDualDisplay() async {
    developer.log('POS: _updateDualDisplay() called with ${cartItems.length} items');
    try {
      await DualDisplayService().showCartItemsFromObjects(
        cartItems,
        BusinessInfo.instance.currencySymbol,
      );
      developer.log('POS: Dual display update completed successfully');
    } catch (e) {
      developer.log('POS: ERROR - Dual display update failed: $e', error: e);
    }
  }
}
