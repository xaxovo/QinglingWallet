import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../util.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(monthTotalsProvider);
    final totalsA = ref.watch(categoryTotalsProvider);
    final catsA = ref.watch(categoriesProvider);
    final trendA = ref.watch(trendProvider);
    final cats = catsA.value ?? const <Category>[];
    final catById = {for (final c in cats) c.id: c};
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          month.when(
            data: (m) => _summaryCard(context, m),
            loading: () => const SizedBox(),
            error: (e, _) => const SizedBox(),
          ),
          const SizedBox(height: 16),
          totalsA.when(
            data: (totals) => _pieCard(context, totals, catById,
                month.value?['expense'] ?? 0),
            loading: () => const SizedBox(
                height: 140, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const SizedBox(),
          ),
          const SizedBox(height: 16),
          trendA.when(
            data: (rows) => _trendCard(context, rows),
            loading: () => const SizedBox(
                height: 180, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, Map<String, double> m) {
    final income = m['income'] ?? 0.0;
    final expense = m['expense'] ?? 0.0;
    final balance = income - expense;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sum('本月收入', income, Colors.green),
            _sum('本月支出', expense, Colors.pinkAccent),
            _sum('结余', balance, Colors.black87),
          ],
        ),
      ),
    );
  }

  Widget _sum(String label, double v, Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45)),
        const SizedBox(height: 6),
        Text('¥${v.toStringAsFixed(0)}',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 17, color: c)),
      ],
    );
  }

  Widget _pieCard(BuildContext context, Map<int, double> totals,
      Map<int, Category> catById, double expense) {
    if (totals.isEmpty) {
      return const Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24))),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
              child:
                  Text('本月还没有支出记录', style: TextStyle(color: Colors.black45))),
        ),
      );
    }
    final total = totals.values.fold<double>(0, (a, b) => a + b);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('支出占比',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 16),
            SizedBox(
              height: 210,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 52,
                  sections: [
                    for (final e in totals.entries)
                      PieChartSectionData(
                        value: e.value,
                        color: Color(catById[e.key]?.color ?? 0xFF9E9E9E),
                        radius: 46,
                        title:
                            '${(e.value / total * 100).toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final e in totals.entries)
                  _legend(catById[e.key]?.name ?? '其他',
                      Color(catById[e.key]?.color ?? 0xFF9E9E9E)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String name, Color c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _trendCard(BuildContext context, List<Map<String, Object?>> rows) {
    final now = DateTime.now();
    final months = <String>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      months.add(DateFormatUtils.key(d));
    }
    final income = <double>[], expense = <double>[];
    for (final m in months) {
      income.add(0);
      expense.add(0);
    }
    for (final r in rows) {
      final idx = months.indexOf(r['m'] as String? ?? '');
      if (idx >= 0) {
        final v = (r['s'] as num?)?.toDouble() ?? 0;
        if (r['type'] == 1) {
          income[idx] = v;
        } else {
          expense[idx] = v;
        }
      }
    }
    final spotsIncome = <FlSpot>[
      for (int i = 0; i < months.length; i++) FlSpot(i.toDouble(), income[i])
    ];
    final spotsExpense = <FlSpot>[
      for (int i = 0; i < months.length; i++) FlSpot(i.toDouble(), expense[i])
    ];
    final labels = [
      for (final m in months) '${int.parse(m.substring(5))}月'
    ];
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('近6个月趋势',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) =>
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                v >= 0 && v < labels.length ? labels[v.toInt()] : '',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spotsIncome,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withOpacity(0.08)),
                    ),
                    LineChartBarData(
                      spots: spotsExpense,
                      isCurved: true,
                      color: Colors.pinkAccent,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: Colors.pinkAccent.withOpacity(0.08)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                _lineLegend(Colors.green, '收入'),
                SizedBox(width: 18),
                _lineLegend(Colors.pinkAccent, '支出'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _lineLegend extends StatelessWidget {
  const _lineLegend(this.color, this.label);
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class DateFormatUtils {
  static String key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
}
