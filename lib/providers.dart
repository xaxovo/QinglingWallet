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

final balanceProvider = FutureProvider<double>((ref) async {
  ref.watch(tickProvider);
  return ref.watch(dbProvider).balance();
});

// ===== 明细筛选 =====
class TxsFilter {
  final int monthOffset; // 0=本月 -1=上月...
  final String q;
  final int catId; // 0=全部
  final int type; // -1=全部 0支出 1收入
  const TxsFilter(
      {this.monthOffset = 0, this.q = '', this.catId = 0, this.type = -1});
  TxsFilter copyWith(
          {int? monthOffset, String? q, int? catId, int? type}) =>
      TxsFilter(
        monthOffset: monthOffset ?? this.monthOffset,
        q: q ?? this.q,
        catId: catId ?? this.catId,
        type: type ?? this.type,
      );
}

final txsFilterProvider = StateProvider<TxsFilter>((ref) => const TxsFilter());

final txsProvider = FutureProvider<List<Tx>>((ref) async {
  ref.watch(tickProvider);
  final f = ref.watch(txsFilterProvider);
  final now = DateTime.now();
  final base = DateTime(now.year, now.month + f.monthOffset, 1);
  final start = base.millisecondsSinceEpoch;
  final end = DateTime(base.year, base.month + 1, 1).millisecondsSinceEpoch;
  return ref.watch(dbProvider).txs(
      startTs: start,
      endTs: end,
      q: f.q,
      catId: f.catId == 0 ? null : f.catId,
      type: f.type == -1 ? null : f.type);
});

// 统计页查看月份偏移
final statsMonthOffsetProvider = StateProvider<int>((ref) => 0);

final monthTotalsProvider = FutureProvider<Map<String, double>>((ref) async {
  ref.watch(tickProvider);
  final off = ref.watch(statsMonthOffsetProvider);
  final now = DateTime.now();
  final base = DateTime(now.year, now.month + off, 1);
  final s = base.millisecondsSinceEpoch;
  final e = DateTime(base.year, base.month + 1, 1).millisecondsSinceEpoch;
  return ref.watch(dbProvider).monthTotals(startTs: s, endTs: e);
});

// 选中月份支出各分类合计（占比环图）
final categoryTotalsProvider = FutureProvider<Map<int, double>>((ref) async {
  ref.watch(tickProvider);
  final off = ref.watch(statsMonthOffsetProvider);
  final now = DateTime.now();
  final base = DateTime(now.year, now.month + off, 1);
  final s = base.millisecondsSinceEpoch;
  final e = DateTime(base.year, base.month + 1, 1).millisecondsSinceEpoch;
  final rows = await ref.watch(dbProvider).categoryTotals(0, s, e);
  return {
    for (final r in rows) r['categoryId'] as int: (r['total'] as num).toDouble(),
  };
});

// 近6个月趋势
final trendProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  ref.watch(tickProvider);
  return ref.watch(dbProvider).monthlyTrend();
});

// ===== 重复记账规则 =====
final rulesProvider = FutureProvider<List<RecurringRule>>((ref) async {
  ref.watch(tickProvider);
  return ref.watch(dbProvider).rules();
});

// 判断规则今天是否命中
bool _hitsToday(RecurringRule r, DateTime now) {
  switch (r.frequency) {
    case 'weekly':
      return r.day == now.weekday; // Mon=1..Sun=7
    case 'monthly':
      return r.day == now.day;
    case 'yearly':
      return r.day == now.month * 100 + now.day;
  }
  return false;
}

// App 回到前台时调用：补记所有今天命中且尚未生成的重复规则，返回补记条数
Future<int> autoFillRecurring(WidgetRef ref) async {
  final db = ref.read(dbProvider);
  final rules = await db.rules();
  final now = DateTime.now();
  final todayStart =
      DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  final todayEnd = todayStart + 86400000;
  int filled = 0;
  for (final r in rules) {
    if (!r.enabled || !_hitsToday(r, now)) continue;
    final has = await db.ruleHasTx(
        r.categoryId, r.amount, r.type, r.note, todayStart, todayEnd);
    if (!has) {
      await db.addTx(r.amount, r.type, r.categoryId, r.note,
          now.millisecondsSinceEpoch);
      filled++;
    }
  }
  if (filled > 0) bumpTick(ref);
  return filled;
}

// 保存/删除后调用，通知所有依赖刷新
void bumpTick(WidgetRef ref) {
  ref.read(tickProvider.notifier).state++;
}
