import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final monthA = ref.watch(monthTotalsProvider);
    final txsA = ref.watch(txsProvider);
    final catsA = ref.watch(categoriesProvider);
    final cats = catsA.value ?? const <Category>[];
    final map = {for (final c in cats) c.id: c};
    final income = monthA.value?['income'] ?? 0.0;
    final expense = monthA.value?['expense'] ?? 0.0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Reveal(delay: const Duration(milliseconds: 0), child: const _Header()),
            const SizedBox(height: 20),
            _Reveal(
              delay: const Duration(milliseconds: 90),
              child: _BalanceCard(
                balance: balanceA.value ?? 0,
                income: income,
                expense: expense,
              ),
            ),
            const SizedBox(height: 20),
            _Reveal(
              delay: const Duration(milliseconds: 180),
              child: _AddButton(onPressed: () => _openAdd(context)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _Reveal(
                delay: const Duration(milliseconds: 270),
                child: _Recent(
                  txs: txsA.value ?? const [],
                  map: map,
                  onAdd: () => _openAdd(context),
                  onEdit: (t) => _openEdit(context, t),
                  onSeeAll: () =>
                      ref.read(tabIndexProvider.notifier).state = 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _shown ? Offset.zero : const Offset(0, 0.06),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  String get _greet {
    final h = DateTime.now().hour;
    if (h < 5) return '夜深了';
    if (h < 11) return '早上好';
    if (h < 13) return '中午好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

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
            Text('$_greet，清零',
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
  const _BalanceCard(
      {required this.balance, required this.income, required this.expense});
  final double balance;
  final double income;
  final double expense;

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
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: balance),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text('¥ ${v.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _mini('本月收入', income),
              const SizedBox(width: 24),
              _mini('本月支出', expense),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, double v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.85), fontSize: 12)),
        const SizedBox(height: 4),
        Text('¥ ${v.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) {
          setState(() => _down = false);
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? 0.95 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF6A7BB), Color(0xFFEC9CAF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC9CAF).withOpacity(0.40),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 6),
                Text('记一笔',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
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
    required this.onSeeAll,
  });
  final List<Tx> txs;
  final Map<int, Category> map;
  final VoidCallback onAdd;
  final void Function(Tx) onEdit;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final recent = txs.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('最近记录',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            TextButton(onPressed: onSeeAll, child: const Text('查看全部')),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: recent.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('还没有记录哦',
                          style: TextStyle(color: Colors.black45)),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add),
                        label: const Text('记第一笔'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(t.note.isEmpty ? '' : t.note),
                        trailing: Text('$sign¥${t.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
