import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user_model.dart';
import '../../models/app_usage_log.dart';
import '../../services/app_monitoring_service.dart';

class ChildActivityPage extends StatefulWidget {
  final AppUser child;

  const ChildActivityPage({super.key, required this.child});

  @override
  State<ChildActivityPage> createState() => _ChildActivityPageState();
}

class _ChildActivityPageState extends State<ChildActivityPage> {
  List<AppUsageLog> _logs = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() => _isLoading = true);

    final since = DateTime.now().subtract(const Duration(days: 7));
    final logs = await appMonitoringService.getLogsForChild(widget.child.uid, since: since);
    final stats = await appMonitoringService.getChildStats(widget.child.uid, since: since);

    if (mounted) {
      setState(() {
        _logs = logs;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Actividad de ${widget.child.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivity,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compliance Score
                  _buildComplianceCard(),

                  const SizedBox(height: 24),

                  // Stats Cards
                  _buildStatsCards(),

                  const SizedBox(height: 24),

                  // Top Apps Chart
                  if ((_stats['topApps'] as Map).isNotEmpty) ...[
                    const Text(
                      'Apps Más Usadas (7 días)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTopAppsChart(),
                    const SizedBox(height: 24),
                  ],

                  // Recent Violations
                  const Text(
                    'Actividad Reciente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentLogs(),
                ],
              ),
            ),
    );
  }

  Widget _buildComplianceCard() {
    final complianceRate = (_stats['complianceRate'] ?? 100.0) as double;
    final color = complianceRate >= 80
        ? Colors.green
        : complianceRate >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade400, color.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Índice de Cumplimiento',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${complianceRate.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getComplianceMessage(complianceRate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getComplianceMessage(double rate) {
    if (rate >= 90) return '¡Excelente! Muy responsable';
    if (rate >= 70) return 'Buen trabajo, sigue así';
    if (rate >= 50) return 'Puede mejorar';
    return 'Necesita más supervisión';
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.list,
            title: 'Apps Usadas',
            value: '${(_stats['topApps'] as Map).length}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.warning,
            title: 'Alertas',
            value: '${_stats['violations'] ?? 0}',
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer,
            title: 'Tiempo Total',
            value: '${_stats['totalMinutes'] ?? 0}m',
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppsChart() {
    final topApps = _stats['topApps'] as Map<String, dynamic>;
    final sortedApps = topApps.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    final topFive = sortedApps.take(5).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (topFive.first.value as int).toDouble() * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < topFive.length) {
                    final appName = topFive[value.toInt()].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        appName.length > 8 ? '${appName.substring(0, 8)}...' : appName,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('${(value / 60).toInt()}m', style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: topFive.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: (entry.value.value as int).toDouble(),
                  color: Colors.purple,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentLogs() {
    if (_logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No hay actividad registrada',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: _logs.take(20).map((log) {
        final isViolation = !log.wasAllowed;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isViolation ? Colors.red[100] : Colors.green[100],
              child: Icon(
                isViolation ? Icons.warning : Icons.check,
                color: isViolation ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            title: Text(log.appName),
            subtitle: Text(
              '${_formatDateTime(log.timestamp)} • ${(log.durationSeconds / 60).toStringAsFixed(1)} min',
            ),
            trailing: isViolation
                ? const Chip(
                    label: Text('No permitida', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(color: Colors.white),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return 'Hoy ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ayer ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }
}
