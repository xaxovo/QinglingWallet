import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../providers.dart';
import '../util.dart';
import 'add_record_sheet.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  void _openEdit(BuildContext context, Tx t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRecordSheet(editTx: t),
    );
  }

  void _openFilter(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _FilterSheet(),
    );
  }

  void _openCalendar(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _CalendarSheet(),
    );
  }

  String _monthLabel(WidgetRef ref) {
    final off = ref.watch(txsFilterProvider).monthOffset;
    final now = DateTime.now();
    final m = DateTime(now.year, now.month + off, 1);
    return '${m.year}年${m.month}月';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txsA = ref.watch(txsProvider);
    final catsA = ref.watch(categoriesProvider);
    final f = ref.watch(txsFilterProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('明细'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _openCalendar(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _monthSwitcher(context, ref),
          _searchBar(context, ref, f),
          _filterBar(context, ref, f, catsA.value ?? const <Category>[]),
          Expanded(
            child: txsA.when(
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
                    child: Text('这个月还没有记录',
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthSwitcher(BuildContext context, WidgetRef ref) {
    final off = ref.watch(txsFilterProvider).monthOffset;
    final set = (int v) =>
        ref.read(txsFilterProvider.notifier).state =
            ref.read(txsFilterProvider).copyWith(monthOffset: v);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => set(off - 1),
        ),
        Text(_monthLabel(ref),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => set(off + 1),
        ),
      ],
    );
  }

  Widget _searchBar(BuildContext context, WidgetRef ref, TxsFilter f) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (v) =>
            ref.read(txsFilterProvider.notifier).state =
                f.copyWith(q: v),
        decoration: InputDecoration(
          hintText: '搜索备注',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _filterBar(BuildContext context, WidgetRef ref, TxsFilter f,
      List<Category> cats) {
    final catById = {for (final c in cats) c.id: c};
    final cat = catById[f.catId];
    final typeLabel = f.type == -1 ? '全部' : (f.type == 0 ? '支出' : '收入');
    final catLabel = cat?.name ?? '全部';
    final hasFilter = f.catId != 0 || f.type != -1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _openFilter(context, ref);
            },
            child: Chip(
              avatar: const Icon(Icons.filter_list, size: 16),
              label: Text(hasFilter ? '$typeLabel · $catLabel' : '筛选'),
              backgroundColor:
                  hasFilter ? const Color(0xFFFDE3EA) : Colors.white,
            ),
          ),
        ],
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
          onTap: () => _openEdit(context, t),
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

// 筛选弹层：分类 + 收支类型
class _FilterSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(txsFilterProvider);
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('筛选',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 14),
          const Text('类型'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _choiceChip(context, ref, '全部', f.type == -1,
                  () => _setType(ref, -1)),
              _choiceChip(context, ref, '支出', f.type == 0,
                  () => _setType(ref, 0)),
              _choiceChip(context, ref, '收入', f.type == 1,
                  () => _setType(ref, 1)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('分类'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _choiceChip(context, ref, '全部', f.catId == 0,
                  () => _setCat(ref, 0)),
              for (final c in cats)
                _choiceChip(context, ref, c.name, f.catId == c.id,
                    () => _setCat(ref, c.id)),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  Widget _choiceChip(BuildContext context, WidgetRef ref, String label,
      bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  void _setType(WidgetRef ref, int v) {
    ref.read(txsFilterProvider.notifier).state =
        ref.read(txsFilterProvider).copyWith(type: v);
  }

  void _setCat(WidgetRef ref, int v) {
    ref.read(txsFilterProvider.notifier).state =
        ref.read(txsFilterProvider).copyWith(catId: v);
  }
}

// 日历视图：月历 + 选某天看当天记录
class _CalendarSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends ConsumerState<_CalendarSheet> {
  late DateTime _view = DateTime.now();
  DateTime? _selected;
  List<Tx> _dayTxs = [];

  @override
  void initState() {
    super.initState();
    _load(DateTime.now());
  }

  Future<void> _load(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = start + 86400000;
    final txs = await ref.read(dbProvider).txs(startTs: start, endTs: end);
    if (mounted) {
      setState(() {
        _selected = day;
        _dayTxs = txs;
      });
    }
  }

  String _ym(DateTime d) => '${d.year}年${d.month}月';

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        // 计算当月首日
        final first = DateTime(_view.year, _view.month, 1);
        final leading = first.weekday - 1; // 周一为0
        final daysInMonth = DateTime(_view.year, _view.month + 1, 0).day;
        final cells = <int?>[];
        for (int i = 0; i < leading; i++) {
          cells.add(null);
        }
        for (int d = 1; d <= daysInMonth; d++) {
          cells.add(d);
        }
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(
                        () => _view = DateTime(_view.year, _view.month - 1, 1)),
                  ),
                  Text(_ym(_view),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(
                        () => _view = DateTime(_view.year, _view.month + 1, 1)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                childAspectRatio: 1,
                children: [
                  for (final w in const ['一', '二', '三', '四', '五', '六', '日'])
                    Center(
                        child:
                            Text(w, style: const TextStyle(fontSize: 12))),
                  for (final c in cells)
                    if (c == null)
                      const SizedBox()
                    else
                      GestureDetector(
                        onTap: () => _load(DateTime(_view.year, _view.month, c)),
                        child: Center(
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selected != null &&
                                      _selected!.year == _view.year &&
                                      _selected!.month == _view.month &&
                                      _selected!.day == c
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$c',
                              style: TextStyle(
                                color: _selected?.day == c &&
                                        _selected?.month == _view.month
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
              const Divider(height: 24),
              if (_selected != null) ...[
                Text(DateFormat('M月d日 EEEE', 'zh_CN').format(_selected!),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
              ],
              if (_dayTxs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('这一天没有记录',
                      style: TextStyle(color: Colors.black45)),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.35),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final t in _dayTxs)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.circle, size: 10),
                          title: Text(t.note.isEmpty ? '记录' : t.note),
                          trailing: Text(
                            '${t.type == 1 ? '+' : '-'}¥${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: t.type == 1
                                    ? Colors.green
                                    : Colors.black87),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
