part of 'categories_management_screen.dart';

extension _CategoriesDialogBuilders on _CategoriesManagementScreenState {
  void _showCategoryDialog({Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(
      text: category?.description ?? '',
    );
    IconData selectedIcon = category?.icon ?? Icons.category;
    Color selectedColor = category?.color ?? Colors.blue;
    int sortOrder = category?.sortOrder ?? _categories.length + 1;
    bool isActive = category?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final icon = await _showIconPicker(context, selectedIcon);
                      if (icon != null) {
                        setDialogState(() {
                          selectedIcon = icon;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Icon',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        children: [
                          Icon(selectedIcon, color: selectedColor),
                          const SizedBox(width: 8),
                          const Text('Tap to change icon'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final color = await _showColorPicker(
                        context,
                        selectedColor,
                      );
                      if (color != null) {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Tap to change color'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: sortOrder.toString(),
                    ),
                    onChanged: (value) {
                      sortOrder = int.tryParse(value) ?? sortOrder;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text('Show this category in POS'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ToastHelper.showToast(
                    context,
                    'Please enter a category name',
                  );
                  return;
                }

                var newCategory = Category(
                  id:
                      category?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descController.text,
                  icon: selectedIcon,
                  color: selectedColor,
                  sortOrder: sortOrder,
                  isActive: isActive,
                  createdAt: category?.createdAt,
                );

                try {
                  if (isEditing) {
                    await (widget.repository ?? DatabaseCategoryRepository())
                        .updateCategory(newCategory);
                  } else {
                    await (widget.repository ?? DatabaseCategoryRepository())
                        .createCategory(newCategory);
                  }

                  setState(() {
                    if (isEditing) {
                      final index = _categories.indexWhere(
                        (c) => c.id == category.id,
                      );
                      if (index != -1) {
                        _categories[index] = newCategory;
                      }
                    } else {
                      _categories.add(newCategory);
                    }
                    _categories.sort(
                      (a, b) => a.sortOrder.compareTo(b.sortOrder),
                    );
                    _filterCategories();
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ToastHelper.showToast(
                    context,
                    isEditing
                        ? 'Category updated successfully'
                        : 'Category added successfully',
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ToastHelper.showToast(context, 'Error saving category: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<IconData?> _showIconPicker(
    BuildContext context,
    IconData current,
  ) async {
    final icons = [
      Icons.category,
      Icons.local_cafe,
      Icons.restaurant,
      Icons.cake,
      Icons.local_pizza,
      Icons.icecream,
      Icons.lunch_dining,
      Icons.breakfast_dining,
      Icons.dinner_dining,
      Icons.liquor,
      Icons.local_bar,
      Icons.fastfood,
      Icons.ramen_dining,
      Icons.emoji_food_beverage,
      Icons.wine_bar,
      Icons.coffee,
    ];

    return showDialog<IconData>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => Navigator.pop(context, icons[index]),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: icons[index] == current
                          ? const Color(0xFF2563EB)
                          : Colors.grey,
                      width: icons[index] == current ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icons[index], size: 32),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<Color?> _showColorPicker(BuildContext context, Color current) async {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
    ];

    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => Navigator.pop(context, colors[index]),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors[index] == current
                          ? Colors.black
                          : Colors.grey,
                      width: colors[index] == current ? 3 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
