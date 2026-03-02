import 'package:extropos/models/table_model.dart';
import 'package:extropos/services/table_management_service.dart';
import 'package:flutter/material.dart';

part 'table_reports_screen_ui.dart';
part 'table_reports_screen_helpers.dart';

class TableReportsScreen extends StatefulWidget {
  const TableReportsScreen({super.key});

  @override
  State<TableReportsScreen> createState() => _TableReportsScreenState();
}

class _TableReportsScreenState extends State<TableReportsScreen> {
  late TableManagementService _tableService;

  @override
  void initState() {
    super.initState();
    _tableService = TableManagementService();
    _initializeTables();
  }

  Future<void> _initializeTables() async {
    await _tableService.loadTablesFromDatabase();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('See table_reports_screen_ui.dart');
  }

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.orange;
      case TableStatus.reserved:
        return Colors.blue;
      case TableStatus.merged:
        return Colors.purple;
      case TableStatus.cleaning:
        return Colors.brown;
    }
  }
}
