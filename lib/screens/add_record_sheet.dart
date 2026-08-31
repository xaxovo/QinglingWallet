import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';
import '../util.dart';
import '../particle.dart';
import '../appearance.dart';

class AddRecordSheet extends ConsumerStatefulWidget {
  const AddRecordSheet({super.key, this.initialCategoryId, this.editTx});
  final int? initialCategoryId;
  final Tx? editTx;

  @override
  ConsumerState<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends ConsumerState<AddRecordSheet> {
  int _type = 0;
  int? _categoryId;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DateTime _date;
  String? _error;

  bool get _isEdit => widget.editTx != null;

  @override
  void initState() {
    super.initState();
    final t = widget.editTx;
    if (t != null) {
      _type = t.type;
      _categoryId = t.categoryId;
      _amount = TextEditingController(text: t.amount.toStringAsFixed(2));
      _note = TextEditingController(text: t.note);
      _date = DateTime.fromMillisecondsSinceEpoch(t.ts);
    } else {
      _amount = TextEditingController();
      _note = TextEditingController();
      _categoryId = widget.initialCategoryId;
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catsA = ref.watch(categoriesProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(_isEdit ? '编辑记录' : '记一笔',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _seg('支出', 0),
                const SizedBox(width: 12),
                _seg('收入', 1),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              autofocus: !_isEdit,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
              ],
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                prefixText: '¥ ',
                hintText: '0.00',
                border: InputBorder.none,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 13)),
              ),
            catsA.when(
              data: (cats) => _categoryGrid(cats),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  color: Colors.black54,
                ),
                Text(DateFormat('M月d日', 'zh_CN').format(_date)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _note,
                    decoration: const InputDecoration(
                        hintText: '备注', border: InputBorder.none),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_isEdit) ...[
                  _deleteBtn(),
                  const SizedBox(width: 12),
                ],
                Expanded(child: _saveBtn()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _seg(String label, int type) {
    final selected = _type == type;
    return _PressScale(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _type = type;
          _categoryId = null;
          _error = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFFF2EEEE),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _categoryGrid(List<Category> cats) {
    final list = cats.where((c) => c.type == _type).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final c in list) _catChip(c)],
    );
  }

  Widget _catChip(Category c) {
    final selected = _categoryId == c.id;
    final color = Color(c.color);
    return _PressScale(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _categoryId = c.id;
          _error = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFFF2EEEE),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconFor(c.icon), size: 16, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(c.name,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = '请输入正确的金额');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = '请选择分类');
      return;
    }
    HapticFeedback.heavyImpact();
    final db = ref.read(dbProvider);
    if (_isEdit) {
      await db.updateTx(widget.editTx!.id, amount, _type, _categoryId!,
          _note.text, _date.millisecondsSinceEpoch);
    } else {
      await db.addTx(amount, _type, _categoryId!, _note.text,
          _date.millisecondsSinceEpoch);
    }
    bumpTick(ref);
    final app = ref.read(appearanceProvider);
    showConfettiBurst(context, effect: app.effect);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _saveBtn() {
    return FilledButton.icon(
      onPressed: _save,
      icon: const Icon(Icons.check),
      label: Text(_isEdit ? '更新' : '保存'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _deleteBtn() {
    return OutlinedButton.icon(
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除这条记录？'),
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
          await ref.read(dbProvider).deleteTx(widget.editTx!.id);
          bumpTick(ref);
          if (mounted) Navigator.of(context).pop();
        }
      },
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('删除'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        foregroundColor: Colors.redAccent,
        side: const BorderSide(color: Colors.redAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
