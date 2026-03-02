part of 'settings_screen.dart';

extension SettingsScreenUIBuilders on _SettingsScreenState {
  Widget _buildSettingsScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, String>>(
          future: _getAppInfo(),
          builder: (context, snapshot) {
            final appInfo =
                snapshot.data ??
                {'version': '1.0.5', 'buildNumber': '5', 'appName': 'ExtroPOS'};
            final trainingService = context.watch<TrainingModeService>();
            final categories = SettingsCategoriesBuilder.buildCategories(
              context,
              appInfo,
              trainingService,
              onShowTutorial: () => _showTutorial(context),
              onShowTrainingModeDialog: () =>
                  SettingsDialogs.showTrainingModeDialog(context),
              onShowUserGuideDialog: () =>
                  SettingsDialogs.showUserGuideDialog(context),
              onShowRequireDbProductsDialog: () =>
                  SettingsDialogs.showRequireDbProductsDialog(context),
              onShowPerformanceReportDialog: () =>
                  SettingsDialogs.showPerformanceReportDialog(context),
              onDownloadLatestApk: () => UpdateDialogs.downloadLatestApk(
                context,
                updateServiceFactory: widget.updateServiceFactory,
                openFileFn: widget.openFileFn,
              ),
              onCheckForUpdates: () => UpdateDialogs.checkForUpdates(
                context,
                updateServiceFactory: widget.updateServiceFactory,
              ),
              onResetPos: () => _handleResetPos(context),
              onClearTrainingData: () => _handleClearTrainingData(context),
              onResetSetup: () => _handleResetSetup(context),
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth >= 600) crossAxisCount = 2;
                if (constraints.maxWidth >= 900) crossAxisCount = 3;
                if (constraints.maxWidth >= 1200) crossAxisCount = 4;

                final activeCategory = _activeCategoryId == null
                    ? null
                    : categories.firstWhere(
                        (category) => category.id == _activeCategoryId,
                        orElse: () => categories.first,
                      );

                return Column(
                  children: [
                    _buildHeader(constraints.maxWidth, activeCategory),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: activeCategory == null
                            ? _buildMainGrid(crossAxisCount, categories)
                            : _buildSubGrid(crossAxisCount, activeCategory),
                      ),
                    ),
                    _buildFooter(appInfo),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double width, SettingsCategory? activeCategory) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (activeCategory != null || canPop)
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: InkWell(
                      onTap: () {
                        if (activeCategory != null) {
                          setState(() => _activeCategoryId = null);
                          return;
                        }
                        if (canPop) {
                          Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeCategory?.title ?? 'System Settings',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeCategory != null
                            ? 'Manage ${activeCategory.title.toLowerCase()} preferences'
                            : 'Select a configuration tile to get started',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (width >= 600)
            ElevatedButton.icon(
              onPressed: () {
                ToastHelper.showToast(
                  context,
                  'Settings are saved automatically',
                );
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: const Color(0xFFE2E8F0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainGrid(int crossAxisCount, List<SettingsCategory> categories) {
    return GridView.builder(
      key: const ValueKey('MainGrid'),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 180,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return SettingsTileWidget(
          title: category.title,
          description: '${category.items.length} management areas available.',
          icon: category.icon,
          color: category.color,
          onTap: () => setState(() => _activeCategoryId = category.id),
        );
      },
    );
  }

  Widget _buildSubGrid(int crossAxisCount, SettingsCategory category) {
    final items = category.items;
    return GridView.builder(
      key: ValueKey('SubGrid_${category.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 180,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return SettingsTileWidget(
          title: item.title,
          description: item.description,
          subLabel: category.title,
          icon: item.icon,
          color: category.color,
          onTap: item.onTap,
        );
      },
    );
  }

  Widget _buildFooter(Map<String, String> appInfo) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${appInfo['appName']} v${appInfo['version']} (Build ${appInfo['buildNumber']})',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsTileWidget extends StatelessWidget {
  final String? title;
  final String? description;
  final String? subLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SettingsTileWidget({
    super.key,
    required this.title,
    required this.description,
    this.subLabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 14),
              if (subLabel != null) ...[
                Text(
                  subLabel!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  description ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
