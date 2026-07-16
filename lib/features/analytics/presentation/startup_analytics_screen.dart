import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_ext.dart';
import 'analytics_providers.dart';

class StartupAnalyticsScreen extends ConsumerWidget {
  const StartupAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(startupAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              _Stat(
                  label: 'Views',
                  value: '${a.totalViews}',
                  icon: Icons.visibility_rounded),
              _Stat(
                  label: 'Applications',
                  value: '${a.totalApplications}',
                  icon: Icons.description_rounded),
              _Stat(
                  label: 'Conversion',
                  value: '${a.conversionRate.toStringAsFixed(1)}%',
                  icon: Icons.percent_rounded),
            ],
          ),
          const SizedBox(height: 24),
          Text('Applications — last 7 days',
              style: context.text.titleMedium),
          const SizedBox(height: 12),
          SizedBox(height: 200, child: _TrendChart(data: a.applicationTrend)),
          const SizedBox(height: 24),
          if (a.applicationsByStatus.isNotEmpty) ...[
            Text('Applications by status', style: context.text.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: _StatusPie(data: a.applicationsByStatus),
            ),
            const SizedBox(height: 24),
          ],
          Text('Top internships', style: context.text.titleMedium),
          const SizedBox(height: 8),
          if (a.topInternships.isEmpty)
            Text('Post an internship to see analytics.',
                style: context.text.bodyMedium)
          else
            ...a.topInternships.map(
              (i) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(i.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${i.viewsCount} views'),
                  trailing: Chip(label: Text('${i.applicantsCount} applied')),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: context.colors.primary),
              const SizedBox(height: 8),
              Text(value, style: context.text.titleLarge),
              Text(label,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.data});
  final List<MapEntry<String, int>> data;

  @override
  Widget build(BuildContext context) {
    final maxY = (data.map((e) => e.value).fold(0, (a, b) => a > b ? a : b))
        .toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 4 : maxY + 1,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(data[i].key,
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: data[i].value.toDouble(),
                width: 16,
                borderRadius: BorderRadius.circular(6),
                color: context.colors.primary,
              ),
            ]),
        ],
      ),
    );
  }
}

class _StatusPie extends StatelessWidget {
  const _StatusPie({required this.data});
  final List<MapEntry<String, int>> data;

  @override
  Widget build(BuildContext context) {
    final colors = [
      context.colors.primary,
      context.colors.secondary,
      context.colors.tertiary,
      context.colors.error,
      Colors.orange,
      Colors.teal,
    ];
    final total = data.fold<int>(0, (s, e) => s + e.value);
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (var i = 0; i < data.length; i++)
                  PieChartSectionData(
                    value: data[i].value.toDouble(),
                    title:
                        '${((data[i].value / total) * 100).round()}%',
                    radius: 46,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                    color: colors[i % colors.length],
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < data.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('${data[i].key} (${data[i].value})',
                            style: context.text.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
