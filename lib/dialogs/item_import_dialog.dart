import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

class ItemImportDialog extends StatefulWidget {
  final Function() onImportComplete;

  const ItemImportDialog({
    required this.onImportComplete,
    super.key,
  });

  @override
  State<ItemImportDialog> createState() => _ItemImportDialogState();
}

class _ItemImportDialogState extends State<ItemImportDialog> {
  final importController = TextEditingController();
  List<Map<String, dynamic>>? _importPreview;

  @override
  void dispose() {
    importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Items'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['json', 'csv', 'txt'],
                    );
                    if (result != null && result.files.single.path != null) {
                      final file = File(result.files.single.path!);
                      final content = await file.readAsString();
                      importController.text = content;
                      try {
                        final preview = await DatabaseService.instance
                            .parseItemsFromContent(content);
                        setState(() {
                          _importPreview = preview;
                        });
                      } catch (e) {
                        setState(() {
                          _importPreview = [];
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Choose file'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final content = importController.text.trim();
                    if (content.isEmpty) {
                      ToastHelper.showToast(
                        context,
                        'Paste or choose a file first',
                      );
                      return;
                    }
                    try {
                      final preview = await DatabaseService.instance
                          .parseItemsFromContent(content);
                      setState(() {
                        _importPreview = preview;
                      });
                    } catch (e) {
                      setState(() {
                        _importPreview = [];
                      });
                      if (!mounted) return;
                      ToastHelper.showToast(context, 'Preview failed: $e');
                    }
                  },
                  icon: const Icon(Icons.remove_red_eye),
                  label: const Text('Preview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: importController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Paste JSON or CSV here',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _importPreview == null
                        ? const Center(child: Text('Preview will appear here'))
                        : _importPreview!.isEmpty
                            ? const Center(child: Text('No preview available'))
                            : Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _importPreview!.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 8),
                                  itemBuilder: (context, index) {
                                    final row = _importPreview![index];
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        row['name']?.toString() ??
                                            row['Name']?.toString() ??
                                            'Unnamed',
                                      ),
                                      subtitle: Text(
                                        'Price: ${row['price'] ?? row['Price'] ?? ''}  •  Category: ${row['category'] ?? row['Category'] ?? ''}',
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final content = importController.text.trim();
            if (content.isEmpty) {
              ToastHelper.showToast(context, 'Paste some content first');
              return;
            }
            try {
              final imported = await DatabaseService.instance
                  .importItemsFromJson(content);
              if (!mounted) return;
              Navigator.pop(context);
              if (mounted) {
                ToastHelper.showToast(
                  context,
                  'Imported $imported items (JSON)',
                );
              }
              widget.onImportComplete();
            } catch (eJson) {
              try {
                final imported = await DatabaseService.instance
                    .importItemsFromCsv(content);
                if (!mounted) return;
                Navigator.pop(context);
                if (mounted) {
                  ToastHelper.showToast(
                    context,
                    'Imported $imported items (CSV)',
                  );
                }
                widget.onImportComplete();
              } catch (eCsv) {
                if (!mounted) return;
                ToastHelper.showToast(context, 'Import failed: $eCsv');
              }
            }
          },
          child: const Text('Import (JSON/CSV)'),
        ),
      ],
    );
  }
}
