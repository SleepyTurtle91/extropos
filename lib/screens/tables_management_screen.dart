import 'package:extropos/models/table_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/responsive_row.dart';
import 'package:flutter/material.dart';

part 'tables_management_operations.dart';
part 'tables_management_content.dart';
part 'tables_management_fab.dart';
part 'tables_management_form_dialog.dart';
part 'tables_management_stat_card.dart';

class TablesManagementScreen extends StatefulWidget {
  const TablesManagementScreen({super.key});

  @override
  State<TablesManagementScreen> createState() => _TablesManagementScreenState();
}

class _TablesManagementScreenState extends State<TablesManagementScreen> {
  List<RestaurantTable> tables = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tables Management'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildStatsSection(),
          _buildTablesGrid(),
        ],
      ),
      floatingActionButton: _buildAddTablesFAB(),
    );
  }
}
