import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../util.dart';
import 'add_record_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddRecordSheet(),
    );
  }

  void _openEdit(BuildContext context, Tx t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRecordSheet(editTx: t),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceA = ref.watch(balanceProvider);
    final txsA = ref.watch(txsProvider);
    final catsA = ref.watch(categoriesProvider);
    final cats = catsA.value ?? const <Category>[];
    final map = {for (final c in cats) c.id: c};
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            const SizedBox(height: 20),
            _BalanceCard(balance: balanceA.value ?? 0),
            const SizedBox(height: 20),
            _AddButton(onPressed: () => _openAdd(context)),
            const SizedBox(height: 20),
            Expanded(
              child: _Recent(
                txs: txsA.value ?? const [],
                map: map,
                onAdd: () => _openAdd(context),
                onEdit: (t) => _openEdit(context, t),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Image.asset('assets/logo.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('你好，清零',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text('把每一笔都记得明明白白',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black.withOpacity(0.45))),
          ],
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final double balance;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('当前余额',
              style: TextStyle(color: Colors.white.withOpacity(0.85))),
          const SizedBox(height: 8),
          Text('¥ ${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('记一笔'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent({
    required this.txs,
    required this.map,
    required this.onAdd,
    required this.onEdit,
  });
  final List<Tx> txs;
  final Map<int, Category> map;
  final VoidCallback onAdd;
  final void Function(Tx) onEdit;

  @override
  Widget build(BuildContext context) {
    final recent = txs.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('最近记录',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('还没有记录哦', style: TextStyle(color: Colors.black45)),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('记第一笔'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = recent[i];
                final c = map[t.categoryId];
                final color = Color(c?.color ?? 0xFF888888);
                final sign = t.type == 1 ? '+' : '-';
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  child: ListTile(
                    onTap: () => onEdit(t),
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(iconFor(c?.icon ?? ''), color: color),
                    ),
                    title: Text(c?.name ?? '未分类',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(t.note.isEmpty ? '' : t.note),
                    trailing: Text('$sign¥${t.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
