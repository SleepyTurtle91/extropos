/// Category-related Models
/// Product categories and category-modifier group associations
library;
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int sortOrder;
  final bool isActive;
  final double taxRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.sortOrder = 0,
    this.isActive = true,
    this.taxRate = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Category copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    int? sortOrder,
    bool? isActive,
    double? taxRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.toARGB32(),
      'sortOrder': sortOrder,
      'isActive': isActive,
      'taxRate': taxRate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      // Use constant icon for web compatibility (tree shaking)
      icon: Icons.category,
      color: Color(json['colorValue'] as int),
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      taxRate: json['taxRate'] as double? ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Represents the link between a category and a modifier group
/// This allows specific categories to have specific modifier groups available
class CategoryModifierGroup {
  final String id;
  final String categoryId;
  final String modifierGroupId;
  final bool
  isRequired; // Override modifier group's isRequired for this category
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModifierGroup({
    required this.id,
    required this.categoryId,
    required this.modifierGroupId,
    this.isRequired = false,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  CategoryModifierGroup copyWith({
    String? id,
    String? categoryId,
    String? modifierGroupId,
    bool? isRequired,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModifierGroup(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      modifierGroupId: modifierGroupId ?? this.modifierGroupId,
      isRequired: isRequired ?? this.isRequired,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'modifier_group_id': modifierGroupId,
      'is_required': isRequired ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CategoryModifierGroup.fromJson(Map<String, dynamic> json) {
    return CategoryModifierGroup(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      modifierGroupId: json['modifier_group_id'] as String,
      isRequired: (json['is_required'] as int?) == 1,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
