import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'data/database.dart';

// 一个"心跳"计数器：任何记账/删除后 +1，让各列表自动刷新
final tickProvider = StateProvider<int>((ref) => 0);

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

// 保存/删除后调用，通知所有依赖刷新
void bumpTick(WidgetRef ref) {
  ref.read(tickProvider.notifier).state++;
}
