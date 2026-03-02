import 'dart:convert';
import 'dart:developer' as developer;

import 'package:csv/csv.dart';
import 'package:extropos/features/auth/services/shift_service.dart';
import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/customer_display_model.dart';
import 'package:extropos/models/customer_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/merchant_model.dart';
import 'package:extropos/models/modifier_group_model.dart';
import 'package:extropos/models/modifier_item_model.dart';
import 'package:extropos/models/payment_models.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/models/table_model.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/error_handler.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/pin_store.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

part 'database_service_parts/database_service_entities.dart';
part 'database_service_parts/database_service_infrastructure.dart';
part 'database_service_parts/database_service_products_categories.dart';
part 'database_service_parts/database_service_products_items.dart';
part 'database_service_parts/database_service_products.dart';
part 'database_service_parts/database_service_reports_advanced.dart';
part 'database_service_parts/database_service_reports_financial.dart';
part 'database_service_parts/database_service_reports_scheduled.dart';
part 'database_service_parts/database_service_sales.dart';

/// Service layer for database operations
/// Provides clean CRUD methods for all entities
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();
}
