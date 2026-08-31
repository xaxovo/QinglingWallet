import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'data/database.dart';

// 一个"心跳"计数器：任何记账/删除后 +1，让各列表自动刷新
final tickProvider = StateProvider<int>((ref) => 0);
final tabIndexProvider = StateProvider<int>((ref) => 0);

final dbProvider = Provider<AppDb>((ref) => AppDb.instance);

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.watch(tickProvider);
  return ref.watch(dbProvider).categories();
});

final txsProvider = FutureProvider<List<Tx>>((ref) async {
  ref.watch(tickProvider);
  return ref.watch(dbProvider).txs();
});

final balanceProvider = FutureProvider<double>((ref) async {
  ref.watch(tickProvider);
  return ref.watch(dbProvider).balance();
});

final monthTotalsProvider = FutureProvider<Map<String, double>>((ref) async {
  ref.watch(tickProvider);
  return ref.watch(dbProvider).monthTotals();
});

// 本月支出各分类合计（categoryId -> total），用于占比环图
final categoryTotalsProvider = FutureProvider<Map<int, double>>((ref) async {
  ref.watch(tickProvider);
  final now = DateTime.now();
  final first = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
  final rows = await ref.watch(dbProvider).categoryTotals(0, first);
  return {
    for (final r in rows) r['categoryId'] as int: (r['total'] as num).toDouble(),
  };
});

// 近6个月趋势（month: 'YYYY-MM', type: 0/1, s: sum）
final trendProvider =
    FutureProvider<List<Map<String, Object?>>>((ref) async {
  ref.watch(tickProvider);
  return ref.watch(dbProvider).monthlyTrend();
});

// 保存/删除后调用，通知所有依赖刷新
void bumpTick(WidgetRef ref) {
  ref.read(tickProvider.notifier).state++;
}
