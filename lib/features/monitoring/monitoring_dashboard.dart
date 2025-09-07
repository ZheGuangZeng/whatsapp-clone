import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/monitoring/monitoring_providers.dart';

/// Comprehensive monitoring dashboard for production observability
class MonitoringDashboard extends ConsumerStatefulWidget {
  const MonitoringDashboard({super.key});

  @override
  ConsumerState<MonitoringDashboard> createState() => _MonitoringDashboardState();
}

class _MonitoringDashboardState extends ConsumerState<MonitoringDashboard> {
  Timer? _refreshTimer;
  int _selectedTab = 0;
  
  @override
  void initState() {
    super.initState();
    // Refresh dashboard every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(monitoringHealthProvider);
      ref.invalidate(performanceStatsProvider);
      ref.invalidate(analyticsStatsProvider);
      ref.invalidate(errorStatsProvider);
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Dashboard'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh data',
          ),
          _buildStatusIndicator(),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildOverviewTab(),
                _buildPerformanceTab(),
                _buildErrorsTab(),
                _buildAnalyticsTab(),
                _buildSystemHealthTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabButton(0, 'Overview', Icons.dashboard),
            _buildTabButton(1, 'Performance', Icons.speed),
            _buildTabButton(2, 'Errors', Icons.error_outline),
            _buildTabButton(3, 'Analytics', Icons.analytics),
            _buildTabButton(4, 'Health', Icons.favorite),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue[700] : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.grey[700],
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: () => setState(() => _selectedTab = index),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Consumer(
      builder: (context, ref, child) {
        final healthStatus = ref.watch(monitoringHealthProvider);
        final isHealthy = healthStatus['initialized'] as bool? ?? false;
        
        return Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isHealthy ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHealthy ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isHealthy ? 'Online' : 'Offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    return Consumer(
      builder: (context, ref, child) {
        final healthStatus = ref.watch(monitoringHealthProvider);
        final performanceStats = ref.watch(performanceStatsProvider);
        final errorStats = ref.watch(errorStatsProvider);
        final analyticsStats = ref.watch(analyticsStatsProvider);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildOverviewCards(healthStatus, performanceStats, errorStats, analyticsStats),
            const SizedBox(height: 20),
            _buildRecentActivity(),
            const SizedBox(height: 20),
            _buildQuickActions(),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCards(
    Map<String, dynamic> healthStatus,
    Map<String, dynamic> performanceStats,
    Map<String, dynamic> errorStats,
    Map<String, dynamic> analyticsStats,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'System Health',
          healthStatus['initialized'] == true ? 'Healthy' : 'Unhealthy',
          Icons.favorite,
          healthStatus['initialized'] == true ? Colors.green : Colors.red,
        ),
        _buildMetricCard(
          'Memory Usage',
          '${(performanceStats['memory_usage_mb'] as double? ?? 0).toStringAsFixed(1)} MB',
          Icons.memory,
          Colors.blue,
        ),
        _buildMetricCard(
          'Total Errors',
          '${errorStats['total_errors'] ?? 0}',
          Icons.error_outline,
          (errorStats['total_errors'] as int? ?? 0) > 0 ? Colors.orange : Colors.green,
        ),
        _buildMetricCard(
          'Events Tracked',
          '${analyticsStats['events_tracked'] ?? 0}',
          Icons.analytics,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return Consumer(
      builder: (context, ref, child) {
        final performanceStats = ref.watch(performanceStatsProvider);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPerformanceOverview(performanceStats),
            const SizedBox(height: 20),
            _buildOperationStats(performanceStats),
            const SizedBox(height: 20),
            _buildPerformanceCharts(),
          ],
        );
      },
    );
  }

  Widget _buildPerformanceOverview(Map<String, dynamic> performanceStats) {
    final memoryUsage = performanceStats['memory_usage_mb'] as double? ?? 0;
    final peakMemory = performanceStats['peak_memory_usage_mb'] as double? ?? 0;
    final currentFps = performanceStats['current_fps'] as double? ?? 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Memory Usage', '${memoryUsage.toStringAsFixed(1)} MB'),
            _buildMetricRow('Peak Memory', '${peakMemory.toStringAsFixed(1)} MB'),
            _buildMetricRow('Current FPS', '${currentFps.toStringAsFixed(1)}'),
            _buildMetricRow('Active Traces', '${performanceStats['active_traces']?.length ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationStats(Map<String, dynamic> performanceStats) {
    final operationStats = performanceStats['operation_stats'] as Map<String, dynamic>? ?? {};

    if (operationStats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Operation Statistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'No operations tracked yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Operation Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...operationStats.entries.map((entry) {
              final stats = entry.value as Map<String, dynamic>;
              return _buildOperationStatsRow(entry.key, stats);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationStatsRow(String operationName, Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            operationName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Count: ${stats['count']}'),
              Text('Avg: ${stats['avg_ms']}ms'),
              Text('P95: ${stats['p95_ms']}ms'),
            ],
          ),
          const Divider(height: 8),
        ],
      ),
    );
  }

  Widget _buildErrorsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final errorStats = ref.watch(errorStatsProvider);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildErrorOverview(errorStats),
            const SizedBox(height: 20),
            _buildMostFrequentErrors(errorStats),
          ],
        );
      },
    );
  }

  Widget _buildErrorOverview(Map<String, dynamic> errorStats) {
    final totalErrors = errorStats['total_errors'] as int? ?? 0;
    final uniqueErrors = errorStats['unique_errors'] as int? ?? 0;
    final queuedErrors = errorStats['queued_errors'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Error Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Total Errors', '$totalErrors'),
            _buildMetricRow('Unique Errors', '$uniqueErrors'),
            _buildMetricRow('Queued Errors', '$queuedErrors'),
            if (totalErrors > 0)
              _buildMetricRow(
                'Error Rate',
                '${(totalErrors / (uniqueErrors > 0 ? uniqueErrors : 1)).toStringAsFixed(2)} per type',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostFrequentErrors(Map<String, dynamic> errorStats) {
    final mostFrequent = errorStats['most_frequent_errors'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Frequent Errors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (mostFrequent.isEmpty)
              Text(
                'No errors recorded',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...mostFrequent.map((error) {
                final errorMap = error as Map<String, dynamic>;
                return ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: Text('Error ID: ${errorMap['error_key']}'),
                  trailing: Chip(
                    label: Text('${errorMap['count']}'),
                    backgroundColor: Colors.red[100],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsStats = ref.watch(analyticsStatsProvider);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAnalyticsOverview(analyticsStats),
            const SizedBox(height: 20),
            _buildTopEvents(analyticsStats),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsOverview(Map<String, dynamic> analyticsStats) {
    final eventsTracked = analyticsStats['events_tracked'] as int? ?? 0;
    final uniqueEvents = analyticsStats['unique_events'] as int? ?? 0;
    final sessionDuration = analyticsStats['session_duration_minutes'] as int? ?? 0;
    final currentUserId = analyticsStats['current_user_id'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Events Tracked', '$eventsTracked'),
            _buildMetricRow('Unique Events', '$uniqueEvents'),
            _buildMetricRow('Session Duration', '${sessionDuration}m'),
            _buildMetricRow('Current User', currentUserId ?? 'Anonymous'),
          ],
        ),
      ),
    );
  }

  Widget _buildTopEvents(Map<String, dynamic> analyticsStats) {
    final topEvents = analyticsStats['top_events'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (topEvents.isEmpty)
              Text(
                'No events tracked yet',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...topEvents.map((event) {
                final eventMap = event as Map<String, dynamic>;
                return ListTile(
                  leading: const Icon(Icons.analytics, color: Colors.purple),
                  title: Text(eventMap['event_name'] as String),
                  trailing: Chip(
                    label: Text('${eventMap['count']}'),
                    backgroundColor: Colors.purple[100],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealthTab() {
    return Consumer(
      builder: (context, ref, child) {
        final healthStatus = ref.watch(monitoringHealthProvider);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHealthOverview(healthStatus),
            const SizedBox(height: 20),
            _buildServiceStatus(healthStatus),
          ],
        );
      },
    );
  }

  Widget _buildHealthOverview(Map<String, dynamic> healthStatus) {
    final isInitialized = healthStatus['initialized'] as bool? ?? false;
    final lastCheck = healthStatus['last_check'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Health',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isInitialized ? Icons.check_circle : Icons.error,
                  color: isInitialized ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isInitialized ? 'System Online' : 'System Offline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isInitialized ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            if (lastCheck != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Last check: $lastCheck',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatus(Map<String, dynamic> healthStatus) {
    final services = healthStatus['services'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...services.entries.map((entry) {
              final isHealthy = entry.value as bool? ?? false;
              return ListTile(
                leading: Icon(
                  isHealthy ? Icons.check_circle : Icons.error,
                  color: isHealthy ? Colors.green : Colors.red,
                ),
                title: Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                trailing: Chip(
                  label: Text(isHealthy ? 'Healthy' : 'Unhealthy'),
                  backgroundColor: isHealthy ? Colors.green[100] : Colors.red[100],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Live activity monitoring coming soon...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCharts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Charts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Performance visualization coming soon...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data'),
                  onPressed: _refreshData,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Errors'),
                  onPressed: _clearErrors,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Export Logs'),
                  onPressed: _exportLogs,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    ref.invalidate(monitoringHealthProvider);
    ref.invalidate(performanceStatsProvider);
    ref.invalidate(analyticsStatsProvider);
    ref.invalidate(errorStatsProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dashboard refreshed')),
    );
  }

  void _clearErrors() {
    final errorReporter = ref.read(errorReporterProvider);
    errorReporter.clearStats();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error statistics cleared')),
    );
  }

  void _exportLogs() {
    // TODO: Implement log export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log export coming soon...')),
    );
  }
}