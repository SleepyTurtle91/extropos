import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/modifier_group_model.dart';
import 'package:extropos/screens/modifier_items_management_screen.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

part 'modifier_groups_management_screen_ui.dart';

class ModifierGroupsManagementScreen extends StatefulWidget {
  const ModifierGroupsManagementScreen({super.key});

  @override
  State<ModifierGroupsManagementScreen> createState() =>
      _ModifierGroupsManagementScreenState();
}

class _ModifierGroupsManagementScreenState
    extends State<ModifierGroupsManagementScreen> {
  final List<ModifierGroup> _groups = [];
  final List<Category> _categories = [];
  List<ModifierGroup> _filteredGroups = [];
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return _buildModifierGroupsManagementScreen(context);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterGroups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() async {
      try {
      final groups = await DatabaseService.instance.getModifierGroups();
      final categories = await DatabaseService.instance.getCategories();
        if (!mounted) return;
      setState(() {
        _groups.clear();
        _groups.addAll(groups);
        _categories.clear();
        _categories.addAll(categories);
        _filteredGroups = List.from(_groups);
      });
    } catch (e) {
        if (!mounted) return;
        ToastHelper.showToast(context, 'Error loading modifier groups: $e');
    }
  }

  void _filterGroups() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = List.from(_groups);
      } else {
        _filteredGroups = _groups
            .where(
              (group) =>
                  group.name.toLowerCase().contains(query) ||
                  group.description.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  void _showGroupDialog({ModifierGroup? group}) {
    final isEditing = group != null;
    final nameController = TextEditingController(text: group?.name ?? '');
    final descController = TextEditingController(
      text: group?.description ?? '',
    );
    final minController = TextEditingController(
      text: group?.minSelection?.toString() ?? '0',
    );
    final maxController = TextEditingController(
      text: group?.maxSelection?.toString() ?? '1',
    );

    bool isRequired = group?.isRequired ?? false;
    bool allowMultiple = group?.allowMultiple ?? false;
    int sortOrder = group?.sortOrder ?? 0;
    List<String> selectedCategories = List.from(group?.categoryIds ?? []);

    final currentContext = context; // capture before async usage
    final parentNavigator = Navigator.of(currentContext);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Modifier Group' : 'Add Modifier Group'),
          content: SingleChildScrollView(
              child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(currentContext).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name *',
                      hintText: 'e.g., Size, Add-ons, Temperature',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Applies to Categories',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leave empty to apply to all categories',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = selectedCategories.contains(cat.id);
                      return FilterChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedCategories.add(cat.id);
                            } else {
                              selectedCategories.remove(cat.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Required'),
                    subtitle: const Text('Customer must make a selection'),
                    value: isRequired,
                    onChanged: (value) {
                      setDialogState(() => isRequired = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Allow Multiple'),
                    subtitle: const Text('Can select multiple modifiers'),
                    value: allowMultiple,
                    onChanged: (value) {
                      setDialogState(() => allowMultiple = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          decoration: const InputDecoration(
                            labelText: 'Min Selection',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          decoration: const InputDecoration(
                            labelText: 'Max Selection',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      sortOrder = int.tryParse(value) ?? 0;
                    },
                    controller: TextEditingController(
                      text: sortOrder.toString(),
                    ),
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
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ToastHelper.showToast(currentContext, 'Please enter a group name');
                  return;
                }

                final newGroup = ModifierGroup(
                  id:
                      group?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  description: descController.text.trim(),
                  categoryIds: selectedCategories,
                  isRequired: isRequired,
                  allowMultiple: allowMultiple,
                  minSelection: int.tryParse(minController.text),
                  maxSelection: int.tryParse(maxController.text),
                  sortOrder: sortOrder,
                  createdAt: group?.createdAt,
                );

                try {
                  if (isEditing) {
                    await DatabaseService.instance.updateModifierGroup(
                      newGroup,
                    );
                  } else {
                    await DatabaseService.instance.insertModifierGroup(
                      newGroup,
                    );
                  }

                  if (!mounted) return;
                  parentNavigator.pop();
                  _loadData();
                  if (mounted) ToastHelper.showToast(context, 'Modifier group ${isEditing ? 'updated' : 'created'} successfully');
                } catch (e) {
                  if (!mounted) return;
                  ToastHelper.showToast(context, 'Error: $e');
                }
                },
              child: Text(isEditing ? 'Update' : 'Create'),
              ),
          ],
        ),
      ),
    );
  }

  void _deleteGroup(ModifierGroup group) {
    final parentNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Modifier Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This will also delete all modifiers in this group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await DatabaseService.instance.deleteModifierGroup(group.id);
                if (!mounted) return;
                parentNavigator.pop();
                _loadData();
                ToastHelper.showToast(context, 'Modifier group deleted successfully');
              } catch (e) {
                if (!mounted) return;
                parentNavigator.pop();
                ToastHelper.showToast(context, 'Error deleting group: $e');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getCategoriesDisplay(List<String> categoryIds) {
    if (categoryIds.isEmpty) return 'All Categories';
    final categoryNames = categoryIds.map((id) {
      final cat = _categories.firstWhere(
        (c) => c.id == id,
        orElse: () => Category(
          id: id,
          name: 'Unknown',
          description: '',
          icon: Icons.help,
          color: Colors.grey,
        ),
      );
      return cat.name;
    }).toList();
    return categoryNames.join(', ');
  }
}

