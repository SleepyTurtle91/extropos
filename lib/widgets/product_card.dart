import 'dart:developer' as developer;
import 'dart:io';

import 'package:extropos/models/product.dart';
import 'package:extropos/theme/design_system.dart';
import 'package:extropos/theme/spacing.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    // Log occasional product card builds to detect excessive rebuilds
    if (kDebugMode) {
      _ProductCardLogger.logBuild(widget.product.name);
    }
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: _hovering
            ? (Matrix4.identity()..scale(1.02))
            : Matrix4.identity(),
        decoration: theme.elevatedCardDecoration.copyWith(
          boxShadow: _hovering
              ? [
                  AppTokens.cardShadow,
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [AppTokens.cardShadow],
        ),
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppSpacing.cardRadius,
            child: Container(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon or Image
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        widget.product.imagePath != null &&
                            widget.product.imagePath!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              File(widget.product.imagePath!),
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              cacheWidth: 88, // Cache at 2x for crisp display
                              cacheHeight: 88,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to icon if image fails to load
                                return Icon(
                                  widget.product.icon,
                                  size: 44,
                                  color: theme.colorScheme.primary,
                                );
                              },
                            ),
                          )
                        : Icon(
                            widget.product.icon,
                            size: 44,
                            color: theme.colorScheme.primary,
                          ),
                  ),

                  // Name
                  const SizedBox(height: AppSpacing.m),
                  Flexible(
                    child: Text(
                      widget.product.name,
                      style: theme.cardTitle,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),

                  // Price
                  const SizedBox(height: AppSpacing.s),
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.s),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.product.getDisplayPrice('RM'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCardLogger {
  static final Map<String, int> _counts = {};

  static void logBuild(String name) {
    final c = (_counts[name] ?? 0) + 1;
    _counts[name] = c;
    // Only log first 10 builds of each product to avoid flooding logs
    if (c <= 10) {
      developer.log(
        'ProductCard.build: $name (count=$c)',
        name: 'product_card',
      );
    }
    // Also periodically dump a summary
    if (c == 10) {
      developer.log(
        'ProductCard.build: Shallow logging limit reached for $name',
        name: 'product_card',
      );
    }
  }
}
