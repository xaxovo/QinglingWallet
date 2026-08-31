import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';
import '../util.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsA = ref.watch(txsProvider);
    final catsA = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('明细'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: txsA.when(
        data: (txs) {
          final cats = catsA.value ?? const <Category>[];
          final map = {for (final c in cats) c.id: c};
          final groups = <String, List<Tx>>{};
          for (final t in txs) {
            final key = DateFormat('yyyy-MM-dd')
                .format(DateTime.fromMillisecondsSinceEpoch(t.ts));
            groups.putIfAbsent(key, () => []).add(t);
          }
          final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
          if (days.isEmpty) {
            return const Center(
              child: Text('还没有记录，去记一笔吧',
                  style: TextStyle(color: Colors.black45)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final day in days) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    DateFormat('M月d日 EEEE', 'zh_CN')
                        .format(DateTime.parse(day)),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                for (final t in groups[day]!)
                  _row(context, ref, t, map[t.categoryId]),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, Tx t, Category? c) {
    final color = Color(c?.color ?? 0xFF888888);
    final sign = t.type == 1 ? '+' : '-';
    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref.read(dbProvider).deleteTx(t.id);
        bumpTick(ref);
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(iconFor(c?.icon ?? ''), color: color),
          ),
          title: Text(c?.name ?? '未分类',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(t.note.isEmpty ? '' : t.note),
          trailing: Text(
            '$sign¥${t.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: t.type == 1 ? Colors.green : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
