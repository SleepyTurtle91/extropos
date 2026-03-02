import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/icon_color_pickers.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

class ItemFormDialog extends StatefulWidget {
  final Item? item;
  final List<Category> categories;
  final Function(Item) onItemSave;

  const ItemFormDialog({
    this.item,
    required this.categories,
    required this.onItemSave,
    super.key,
  });

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController priceController;
  late TextEditingController costController;
  late TextEditingController skuController;
  late TextEditingController barcodeController;
  late TextEditingController stockController;
  late TextEditingController lowStockThresholdController;
  late TextEditingController grabPriceController;
  late TextEditingController shopeePriceController;
  late TextEditingController foodpandaPriceController;

  late String selectedCategoryId;
  late IconData selectedIcon;
  late Color selectedColor;
  bool isAvailable = true;
  bool isFeatured = false;
  bool trackStock = false;
  String? selectedImagePath;
  String? selectedPrinterOverride;
  List<dynamic> availablePrinters = [];
  bool loadingPrinters = true;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    
    nameController = TextEditingController(text: item?.name ?? '');
    descController = TextEditingController(text: item?.description ?? '');
    priceController = TextEditingController(text: item?.price.toString() ?? '');
    costController = TextEditingController(text: item?.cost?.toString() ?? '');
    skuController = TextEditingController(text: item?.sku ?? '');
    barcodeController = TextEditingController(text: item?.barcode ?? '');
    stockController = TextEditingController(text: item?.stock.toString() ?? '0');
    lowStockThresholdController = TextEditingController(
      text: item?.lowStockThreshold.toString() ?? '5',
    );
    grabPriceController = TextEditingController(
      text: item?.merchantPrices['grabfood']?.toStringAsFixed(2) ?? '',
    );
    shopeePriceController = TextEditingController(
      text: item?.merchantPrices['shopeefood']?.toStringAsFixed(2) ?? '',
    );
    foodpandaPriceController = TextEditingController(
      text: item?.merchantPrices['foodpanda']?.toStringAsFixed(2) ?? '',
    );

    selectedCategoryId = item?.categoryId ?? widget.categories.first.id;
    selectedIcon = item?.icon ?? Icons.shopping_bag;
    selectedColor = item?.color ?? Colors.blue;
    isAvailable = item?.isAvailable ?? true;
    isFeatured = item?.isFeatured ?? false;
    trackStock = item?.trackStock ?? false;
    selectedImagePath = item?.imageUrl;
    selectedPrinterOverride = item?.printerOverride;

    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    try {
      final printers = await DatabaseService.instance.getPrinters();
      final kitchenAndBarPrinters = printers
          .where((p) => p.type == PrinterType.kitchen || p.type == PrinterType.bar)
          .toList();
      setState(() {
        availablePrinters = kitchenAndBarPrinters;
        loadingPrinters = false;
      });
    } catch (e) {
      setState(() => loadingPrinters = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    priceController.dispose();
    costController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    stockController.dispose();
    lowStockThresholdController.dispose();
    grabPriceController.dispose();
    shopeePriceController.dispose();
    foodpandaPriceController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (nameController.text.isEmpty) {
      ToastHelper.showToast(context, 'Please enter an item name');
      return;
    }

    final price = double.tryParse(priceController.text);
    if (price == null || price <= 0) {
      ToastHelper.showToast(context, 'Please enter a valid price');
      return;
    }

    String? localImage = selectedImagePath;
    try {
      if (selectedImagePath != null && selectedImagePath!.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        if (!selectedImagePath!.startsWith(appDir.path)) {
          final imagesDir = Directory(p.join(appDir.path, 'images'));
          if (!imagesDir.existsSync()) {
            await imagesDir.create(recursive: true);
          }
          final ext = p.extension(selectedImagePath!);
          final filename = 'item_${DateTime.now().millisecondsSinceEpoch}$ext';
          final dest = p.join(imagesDir.path, filename);
          await File(selectedImagePath!).copy(dest);
          localImage = dest;
        }
      }
    } catch (e) {
      localImage = selectedImagePath;
    }

    final Map<String, double> merchantPrices = {};
    final grabVal = double.tryParse(grabPriceController.text);
    final shopeeVal = double.tryParse(shopeePriceController.text);
    final foodpandaVal = double.tryParse(foodpandaPriceController.text);
    
    if (grabVal != null && grabVal > 0) merchantPrices['grabfood'] = grabVal;
    if (shopeeVal != null && shopeeVal > 0) merchantPrices['shopeefood'] = shopeeVal;
    if (foodpandaVal != null && foodpandaVal > 0) merchantPrices['foodpanda'] = foodpandaVal;

    final newItem = Item(
      id: widget.item?.id ?? '',
      name: nameController.text,
      description: descController.text,
      price: price,
      cost: double.tryParse(costController.text),
      sku: skuController.text,
      barcode: barcodeController.text,
      categoryId: selectedCategoryId,
      icon: selectedIcon,
      color: selectedColor,
      imageUrl: localImage,
      isAvailable: isAvailable,
      isFeatured: isFeatured,
      trackStock: trackStock,
      stock: int.tryParse(stockController.text) ?? 0,
      lowStockThreshold: int.tryParse(lowStockThresholdController.text) ?? 5,
      merchantPrices: merchantPrices,
      printerOverride: selectedPrinterOverride,
    );

    widget.onItemSave(newItem);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'Edit Item' : 'Add Item'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: (selectedImagePath != null &&
                            selectedImagePath!.isNotEmpty)
                        ? Image.file(File(selectedImagePath!), fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 36, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform
                              .pickFiles(type: FileType.image);
                          if (result != null &&
                              result.files.single.path != null) {
                            setState(() {
                              selectedImagePath = result.files.single.path!;
                            });
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Image'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() => selectedImagePath = null);
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
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
              DropdownButtonFormField<String>(
                initialValue: selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: widget.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Row(
                      children: [
                        Icon(cat.icon, color: cat.color, size: 20),
                        const SizedBox(width: 8),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedCategoryId = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Printer dropdown and icon/color pickers
              DropdownButtonFormField<String?>(
                initialValue: selectedPrinterOverride,
                decoration: const InputDecoration(
                  labelText: 'Kitchen/Bar Printer (Optional)',
                  hintText: 'Use category-based printer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.print),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Use category-based printer'),
                  ),
                  ...availablePrinters.map((printer) {
                    return DropdownMenuItem<String?>(
                      value: printer.id,
                      child: Text(printer.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => selectedPrinterOverride = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final icon = await IconColorPickers.showIconPicker(
                          context,
                          selectedIcon,
                        );
                        if (icon != null) {
                          setState(() => selectedIcon = icon);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Icon',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          children: [
                            Icon(selectedIcon, size: 32),
                            const SizedBox(width: 8),
                            const Text('Tap to change'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final color = await IconColorPickers.showColorPicker(
                          context,
                          selectedColor,
                        );
                        if (color != null) {
                          setState(() => selectedColor = color);
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
                            const Text('Tap to change'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Available'),
                      subtitle: const Text('Show in POS'),
                      value: isAvailable,
                      onChanged: (value) {
                        setState(() => isAvailable = value);
                      },
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Featured'),
                      subtitle: const Text('Highlight item'),
                      value: isFeatured,
                      onChanged: (value) {
                        setState(() => isFeatured = value);
                      },
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Track Stock'),
                subtitle: const Text('Monitor inventory levels'),
                value: trackStock,
                onChanged: (value) {
                  setState(() => trackStock = value);
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
          onPressed: _saveItem,
          child: Text(widget.item != null ? 'Update Item' : 'Add Item'),
        ),
      ],
    );
  }
}
