import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/study_category.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final last7Days = storageService.getLast7Days();
    final dailyGoal = storageService.getDailyGoal();
    final todayMinutes = storageService.getTodayStudyTime() ~/ 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Daily Goal Progress
          _buildGoalCard(context, todayMinutes, dailyGoal),
          
          const SizedBox(height: 30),
          
          // Chart Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Últimos 7 días',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Meta: $dailyGoal min',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Bar Chart
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: dailyGoal.toDouble() * 1.5,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = last7Days[group.x.toInt()];
                      final minutes = day['minutes'] as int;
                      return BarTooltipItem(
                        '$minutes min\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: DateFormat('d MMM').format(day['date'] as DateTime),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < last7Days.length) {
                          final day = last7Days[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('E').format(day['date'] as DateTime)[0],
                              style: const TextStyle(fontSize: 12),
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
                        if (value == 0) return const Text('0');
                        if (value == dailyGoal) {
                          return Text('$dailyGoal');
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: dailyGoal.toDouble(),
                  getDrawingHorizontalLine: (value) {
                    if (value == dailyGoal) {
                      return FlLine(
                        color: Colors.amber,
                        strokeWidth: 2,
                        dashArray: [5, 5],
                      );
                    }
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 0.5,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey[300]!),
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                barGroups: List.generate(
                  last7Days.length,
                  (index) {
                    final data = last7Days[index];
                    final minutes = (data['minutes'] as int).toDouble();
                    final isToday = index == last7Days.length - 1;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: minutes,
                          color: minutes >= dailyGoal
                              ? Colors.green
                              : (isToday
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                          width: 30,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Category Distribution
          _buildCategorySection(context),
          
          const SizedBox(height: 30),
          
          // Stats Summary
          _buildSummaryCard(context),
        ],
      ),
    );
  }
  
  Widget _buildCategorySection(BuildContext context) {
    final categoryStats = storageService.getCategoryStats();
    
    if (categoryStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.category,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sin categorías aún',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Empieza a estudiar y selecciona categorías',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    final total = categoryStats.values.fold<int>(0, (sum, val) => sum + val);
    final sortedEntries = categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Por Categoría',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        
        // Pie Chart
        SizedBox(
          height: 200,
          child: Row(
            children: [
              // Chart
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: sortedEntries.take(5).map((entry) {
                      final category = getCategoryById(entry.key);
                      if (category == null) return null;
                      
                      final percentage = (entry.value / total * 100).toInt();
                      
                      return PieChartSectionData(
                        color: category.color,
                        value: entry.value.toDouble(),
                        title: '$percentage%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).whereType<PieChartSectionData>().toList(),
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Legend
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedEntries.take(5).map((entry) {
                    final category = getCategoryById(entry.key);
                    if (category == null) return const SizedBox.shrink();
                    
                    final minutes = entry.value ~/ 60;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: category.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '$minutes min',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, int current, int goal) {
    final progress = (current / goal).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: progress >= 1.0
              ? [Colors.green, Colors.green[700]!]
              : [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.primary)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meta de Hoy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (progress >= 1.0)
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 28,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$current',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' / $goal min',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1.0
                ? '¡Meta cumplida! 🎉'
                : '$percentage% completado',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final totalTime = storageService.getTotalStudyTime();
    final streak = storageService.getCurrentStreak();
    final last7Days = storageService.getLast7Days();
    final weekTotal = last7Days.fold<int>(
      0,
      (sum, day) => sum + (day['minutes'] as int),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Esta semana',
            '$weekTotal min',
            Icons.calendar_today,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            '${totalTime ~/ 60} min',
            Icons.school,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Racha',
            '$streak ${streak == 1 ? "día" : "días"}',
            Icons.local_fire_department,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
