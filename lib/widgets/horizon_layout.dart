import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/widgets/horizon_header.dart';
import 'package:extropos/widgets/horizon_sidebar.dart';
import 'package:flutter/material.dart';

/// Horizon Design System - Main Layout Wrapper
/// Combines sidebar + header + responsive content area
class HorizonLayout extends StatefulWidget {
  final Widget child;
  final List<String> breadcrumbs;
  final String currentRoute;

  const HorizonLayout({
    super.key,
    required this.child,
    this.breadcrumbs = const ['Dashboard'],
    this.currentRoute = '/',
  });

  @override
  State<HorizonLayout> createState() => _HorizonLayoutState();
}

class _HorizonLayoutState extends State<HorizonLayout> {
  bool _isSidebarCollapsed = false;
  bool _isMobileMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

        return Scaffold(
          backgroundColor: HorizonColors.paleSlate,
          body: Stack(
            children: [
              // Main content
              Row(
                children: [
                  // Desktop sidebar (always visible on desktop)
                  if (!isMobile)
                    HorizonSidebar(
                      isCollapsed: _isSidebarCollapsed || isTablet,
                      onToggleCollapse: (collapsed) {
                        setState(() {
                          _isSidebarCollapsed = collapsed;
                        });
                      },
                      currentRoute: widget.currentRoute,
                    ),

                  // Content area
                  Expanded(
                    child: Column(
                      children: [
                        // Header
                        HorizonHeader(
                          breadcrumbs: widget.breadcrumbs,
                          showMenu: isMobile,
                          onMenuTap: () {
                            setState(() {
                              _isMobileMenuOpen = !_isMobileMenuOpen;
                            });
                          },
                        ),

                        // Main content with padding
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            child: widget.child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Mobile sidebar overlay
              if (isMobile && _isMobileMenuOpen)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMobileMenuOpen = false;
                    });
                  },
                  child: Container(
                    color: HorizonColors.overlay,
                  ),
                ),

              // Mobile sidebar drawer
              if (isMobile && _isMobileMenuOpen)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: HorizonSidebar(
                    isCollapsed: false,
                    onToggleCollapse: (collapsed) {
                      setState(() {
                        _isMobileMenuOpen = false;
                      });
                    },
                    currentRoute: widget.currentRoute,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Responsive Grid Helper
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 600) {
          columns = 1;
        } else if (constraints.maxWidth < 900) {
          columns = 2;
        } else if (constraints.maxWidth < 1200) {
          columns = 3;
        }

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: (constraints.maxWidth - (spacing * (columns - 1))) / columns,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}
