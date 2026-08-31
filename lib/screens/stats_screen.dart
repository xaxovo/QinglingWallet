import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(monthTotalsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: month.when(
        data: (m) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('本月支出 ¥ ${m['expense']!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('本月收入 ¥ ${m['income']!.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              const Text('分类占比 / 趋势图 即将上线',
                  style: TextStyle(color: Colors.black45)),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
