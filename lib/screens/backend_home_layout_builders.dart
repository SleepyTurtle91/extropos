part of 'backend_home_screen.dart';

/// Extension providing responsive layout builders for backend home screen
extension _BackendHomeLayoutBuilders on _BackendHomeScreenState {
  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWelcomeCard(),
        if (AppwriteService.isEnabled) ...[
          const SizedBox(height: 24),
          _buildSyncStatusCard(),
          const SizedBox(height: 24),
        ],
        const Text(
          'Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildManagementTilesWidget(),
        const SizedBox(height: 24),
        const Text(
          'Reports',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._buildReportsTiles(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(right: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            children: [
              _buildWelcomeCard(),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'MANAGEMENT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    _buildManagementTilesWidget(),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'REPORTS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ..._buildReportsTiles(),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: Center(
            child: AppwriteService.isEnabled
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSyncStatusCard(),
                      const SizedBox(height: 32),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        // Top section with welcome and sync status
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildWelcomeCard(),
              if (AppwriteService.isEnabled) ...[
                const SizedBox(height: 16),
                _buildSyncStatusCard(),
              ],
            ],
          ),
        ),
        const Divider(),
        // Bottom section with management tiles in a responsive grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
                  ResponsiveHelper.getAdaptiveCrossAxisCountFromConstraints(
                    constraints,
                    minColumns: 1,
                    maxColumns: 4,
                  );

              return GridView.count(
                crossAxisCount: crossAxisCount,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  ..._buildReportsTiles(),
                  ..._buildManagementTilesGrid(crossAxisCount),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
