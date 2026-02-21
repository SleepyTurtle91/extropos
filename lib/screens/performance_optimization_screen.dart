import 'package:extropos/services/image_optimization_service.dart';
import 'package:extropos/services/lazy_loading_service.dart';
import 'package:extropos/services/memory_manager.dart';
import 'package:extropos/services/performance_monitor.dart';
import 'package:flutter/material.dart';

/// Performance optimization dashboard screen
class PerformanceOptimizationScreen extends StatefulWidget {
  const PerformanceOptimizationScreen({super.key});

  @override
  State<PerformanceOptimizationScreen> createState() => _PerformanceOptimizationScreenState();
}

class _PerformanceOptimizationScreenState extends State<PerformanceOptimizationScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Optimization'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Monitor', icon: Icon(Icons.monitor)),
            Tab(text: 'Cache', icon: Icon(Icons.cached)),
            Tab(text: 'Memory', icon: Icon(Icons.memory)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _toggleMonitoring,
            icon: Icon(_isMonitoring ? Icons.pause : Icons.play_arrow),
            tooltip: _isMonitoring ? 'Pause Monitoring' : 'Start Monitoring',
          ),
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonitorTab(),
          _buildCacheTab(),
          _buildMemoryTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildMonitorTab() {
    final stats = PerformanceMonitor.instance.getAllStats();
    final slowOps = PerformanceMonitor.instance.getSlowOperations();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Performance Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard('Operations', stats.length.toString()),
                    const SizedBox(width: 16),
                    _buildStatCard('Slow Ops', slowOps.length.toString(), color: Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Slow Operations
        if (slowOps.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Slow Operations (>100ms)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...slowOps.map((stat) => ListTile(
                    title: Text(stat.operationName),
                    subtitle: Text('${stat.avgMs.toStringAsFixed(1)}ms avg (${stat.count} ops)'),
                    trailing: Text(stat.performanceRating),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // All Operations
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Operations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...stats.values.map((stat) => ListTile(
                  title: Text(stat.operationName),
                  subtitle: Text('${stat.avgMs.toStringAsFixed(1)}ms avg'),
                  trailing: Text(stat.performanceRating),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCacheTab() {
    final lazyStats = LazyLoadingService.instance.getCacheStats();
    final imageStats = ImageOptimizationService.instance.getCacheStats();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Lazy Loading Cache
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lazy Loading Cache',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStatCard('Product Cache', lazyStats['product_cache_entries'].toString()),
                const SizedBox(height: 8),
                _buildStatCard('Category Cache', lazyStats['category_cache_entries'].toString()),
                const SizedBox(height: 8),
                _buildStatCard('Memory Usage', '${lazyStats['cache_memory_estimate_kb']} KB'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Image Cache
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Image Cache',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStatCard('Memory Cache', imageStats['memory_cache_entries'].toString()),
                const SizedBox(height: 8),
                _buildStatCard('Memory Size', '${imageStats['memory_cache_size_kb']} KB'),
                const SizedBox(height: 8),
                _buildStatCard('Expired', imageStats['expired_entries'].toString(), color: Colors.red),
                const SizedBox(height: 8),
                _buildStatCard('Disk Cache', imageStats['disk_cache_initialized'] ? 'Yes' : 'No'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Cache Actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cache Management',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          LazyLoadingService.instance.clearCache();
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lazy loading cache cleared')),
                          );
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear Lazy Cache'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          ImageOptimizationService.instance.clearMemoryCache();
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Image memory cache cleared')),
                          );
                        },
                        icon: const Icon(Icons.image),
                        label: const Text('Clear Image Cache'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryTab() {
    final memoryStats = MemoryManager.instance.getMemoryStats();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Memory Statistics
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Memory Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStatCard('Resources', memoryStats['registered_resources'].toString()),
                const SizedBox(height: 8),
                _buildStatCard('Active Pools', memoryStats['active_pools'].toString()),
                const SizedBox(height: 8),
                _buildStatCard('Pool Resources', memoryStats['total_pool_resources'].toString()),
                const SizedBox(height: 8),
                _buildStatCard('Expired', memoryStats['expired_resources'].toString(), color: Colors.red),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Memory Actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Memory Management',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    MemoryManager.instance.cleanupExpiredResources();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Expired resources cleaned up')),
                    );
                  },
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Cleanup Expired Resources'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    MemoryManager.instance.suggestGC();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Garbage collection suggested')),
                    );
                  },
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Suggest GC'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Performance monitoring and optimization settings will be available here.'),
                const SizedBox(height: 16),
                const Text(
                  'Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Lazy loading configuration'),
                const Text('• Image optimization settings'),
                const Text('• Memory management options'),
                const Text('• Performance thresholds'),
                const Text('• Cache size limits'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.blue,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;
    });

    if (_isMonitoring) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Performance monitoring started')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Performance monitoring paused')),
      );
    }
  }

  void _refreshData() {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Performance data refreshed')),
    );
  }
}