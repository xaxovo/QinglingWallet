import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../util.dart';

class RecurringManageScreen extends ConsumerWidget {
  const RecurringManageScreen({super.key});

  void _openEdit(BuildContext context, RecurringRule? r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RuleEditSheet(r: r),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesA = ref.watch(rulesProvider);
    final catsA = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('自动记账'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: rulesA.when(
        data: (rules) {
          if (rules.isEmpty) {
            return const Center(
              child: Text('还没有重复规则，点右下角新增',
                  style: TextStyle(color: Colors.black45)),
            );
          }
          final cats = catsA.value ?? const <Category>[];
          final map = {for (final c in cats) c.id: c};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final r in rules) _card(context, ref, r, map[r.categoryId]),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEdit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('新增规则'),
      ),
    );
  }

  String _freqLabel(RecurringRule r) {
    switch (r.frequency) {
      case 'weekly':
        return '每周${_weekday(r.day)}';
      case 'monthly':
        return '每月${r.day}号';
      case 'yearly':
        return '每年${(r.day ~/ 100)}月${(r.day % 100)}日';
    }
    return '';
  }

  String _weekday(int d) {
    const names = ['', '一', '二', '三', '四', '五', '六', '日'];
    return d >= 1 && d <= 7 ? names[d] : '${d}';
  }

  Widget _card(BuildContext context, WidgetRef ref, RecurringRule r,
      Category? cat) {
    final color = Color(cat?.color ?? 0xFF888888);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _openEdit(context, r),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(iconFor(cat?.icon ?? ''), color: color),
        ),
        title: Text('${r.name}  ¥${r.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_freqLabel(r)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            r.enabled
                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                : const Icon(Icons.remove_circle_outline,
                    color: Colors.black26, size: 20),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _RuleEditSheet extends ConsumerStatefulWidget {
  const _RuleEditSheet({this.r});
  final RecurringRule? r;

  @override
  ConsumerState<_RuleEditSheet> createState() => _RuleEditSheetState();
}

class _RuleEditSheetState extends ConsumerState<_RuleEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late int _categoryId;
  late int _type;
  late String _frequency;
  late int _day;
  late int _monthSel;
  late bool _enabled;

  bool get _isEdit => widget.r != null;

  @override
  void initState() {
    super.initState();
    final r = widget.r;
    _name = TextEditingController(text: r?.name ?? '');
    _amount = TextEditingController(
        text: r == null ? '' : r.amount.toStringAsFixed(2));
    _note = TextEditingController(text: r?.note ?? '');
    _categoryId = r?.categoryId ?? 0;
    _type = r?.type ?? 0;
    _frequency = r?.frequency ?? 'monthly';
    _day = r?.day ?? 1;
    _monthSel = (r?.day ?? 101) ~/ 100 < 1 ? 1 : (r?.day ?? 101) ~/ 100;
    if (_frequency == 'yearly' && _monthSel < 1) _monthSel = 1;
    _enabled = r?.enabled ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(_isEdit ? '编辑规则' : '新增规则',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                decoration: _dec('规则名称（如 房租 / 工资）'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec('金额'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _seg('支出', 0),
                  const SizedBox(width: 10),
                  _seg('收入', 1),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _categoryId,
                items: [
                  for (final c in cats)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v ?? 0),
                decoration: _dec('分类'),
              ),
              const SizedBox(height: 14),
              // 周期选择（分段 + 日期积木 / 月+日积木）
              _periodPicker(),
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                decoration: _dec('备注（可选）'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('启用'),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_isEdit) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('删除'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: Text(_isEdit ? '更新' : '保存'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==== 周期选择：分段 + 内容 ====
  Widget _periodPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分段切换
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EDED),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              for (final f in const [
                ('weekly', '每周'),
                ('monthly', '每月'),
                ('yearly', '每年'),
              ])
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _frequency = f.$1;
                        if (f.$1 == 'weekly') {
                          _day = _day.clamp(1, 7);
                        } else if (f.$1 == 'monthly') {
                          _day = _day.clamp(1, 31);
                        } else {
                          _day = _day.clamp(1, 31);
                          if (_monthSel < 1) _monthSel = 1;
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _frequency == f.$1
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _frequency == f.$1
                              ? Colors.white
                              : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.15), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_frequency), child: _periodBody()),
        ),
      ],
    );
  }

  Widget _periodBody() {
    if (_frequency == 'weekly') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int d = 1; d <= 7; d++) _roundChip(_weekdayName(d), _day == d,
              () => setState(() => _day = d)),
        ],
      );
    }
    if (_frequency == 'monthly') {
      return _dayGrid();
    }
    // yearly: 月份格 + 日期格
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text('月份',
              style: TextStyle(fontSize: 12, color: Colors.black45)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int m = 1; m <= 12; m++)
              _roundChip('$m月', _monthSel == m,
                  () => setState(() => _monthSel = m)),
          ],
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text('日期',
              style: TextStyle(fontSize: 12, color: Colors.black45)),
        ),
        _dayGrid(),
      ],
    );
  }

  Widget _dayGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int d = 1; d <= 31; d++) _roundChip('$d', _day == d,
            () => setState(() => _day = d)),
      ],
    );
  }

  Widget _roundChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFFF4F0F0),
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _weekdayName(int d) {
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[d];
  }

  Widget _seg(String label, int type) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _type = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFFF2EEEE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F3F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  Future<void> _save() async {
    final name = _name.text.trim();
    final amount = double.tryParse(_amount.text);
    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写名称和有效金额')));
      return;
    }
    HapticFeedback.mediumImpact();
    final int dayEncoded = _frequency == 'yearly'
        ? _monthSel * 100 + _day
        : _day;
    final rule = RecurringRule(
      id: widget.r?.id ?? 0,
      name: name,
      amount: amount,
      categoryId: _categoryId,
      type: _type,
      frequency: _frequency,
      day: dayEncoded,
      note: _note.text.trim(),
      enabled: _enabled,
    );
    final db = ref.read(dbProvider);
    if (_isEdit) {
      await db.updateRule(rule);
    } else {
      await db.addRule(rule);
    }
    bumpTick(ref);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除规则'),
        content: const Text('确定删除这条自动记账规则？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(dbProvider).deleteRule(widget.r!.id);
      bumpTick(ref);
      if (mounted) Navigator.of(context).pop();
    }
  }
}
