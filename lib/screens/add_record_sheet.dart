import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';
import '../util.dart';

class AddRecordSheet extends ConsumerStatefulWidget {
  const AddRecordSheet({super.key, this.initialCategoryId});
  final int? initialCategoryId;

  @override
  ConsumerState<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends ConsumerState<AddRecordSheet> {
  int _type = 0;
  int? _categoryId;
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              autofocus: true,
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
            const SizedBox(height: 12),
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
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('保存'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seg(String label, int type) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() {
        _type = type;
        _categoryId = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFFF4F0F0),
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
      children: [
        for (final c in list)
          ChoiceChip(
            selected: _categoryId == c.id,
            onSelected: (_) => setState(() => _categoryId = c.id),
            avatar: Icon(iconFor(c.icon), color: Color(c.color), size: 18),
            label: Text(c.name),
            labelStyle: TextStyle(
                color:
                    _categoryId == c.id ? Colors.white : Colors.black87),
            selectedColor: Theme.of(context).colorScheme.primary,
            backgroundColor: const Color(0xFFF4F0F0),
          ),
      ],
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入金额')));
      return;
    }
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择分类')));
      return;
    }
    HapticFeedback.heavyImpact();
    await ref.read(dbProvider).addTx(
        amount, _type, _categoryId!, _note.text, _date.millisecondsSinceEpoch);
    bumpTick(ref);
    if (mounted) Navigator.of(context).pop();
  }
}
