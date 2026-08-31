import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../util.dart';

const List<String> _iconNames = [
  'restaurant', 'directions_car', 'shopping_bag', 'sports_esports',
  'home', 'local_hospital', 'more_horiz', 'payments', 'celebration', 'redeem',
  'pets', 'music_note', 'card_travel', 'flight', 'school', 'phone_iphone',
  'shopping_cart', 'savings', 'fitness_center',
];

const List<Color> _colorChoices = [
  Color(0xFFFF8A65), Color(0xFF64B5F6), Color(0xFF9575CD), Color(0xFF4DB6AC),
  Color(0xFFFFB74D), Color(0xFFF06292), Color(0xFF9E9E9E), Color(0xFF81C784),
  Color(0xFFFFD54F), Color(0xFFF48FB1), Color(0xFF7986CB), Color(0xFF4DD0E1),
];

class CategoryManageScreen extends ConsumerWidget {
  const CategoryManageScreen({super.key});

  void _openEdit(BuildContext context, Category? c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryEditSheet(c: c),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsA = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: catsA.when(
        data: (cats) {
          final exp = cats.where((c) => c.type == 0).toList();
          final inc = cats.where((c) => c.type == 1).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _section(context, ref, '支出', exp),
              const SizedBox(height: 20),
              _section(context, ref, '收入', inc),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEdit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('新增分类'),
      ),
    );
  }

  Widget _section(
      BuildContext context, WidgetRef ref, String title, List<Category> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        for (final c in list)
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(c.color).withOpacity(0.15),
                child: Icon(iconFor(c.icon), color: Color(c.color)),
              ),
              title: Text(c.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.edit_outlined, size: 18),
              onTap: () => _openEdit(context, c),
            ),
          ),
      ],
    );
  }
}

class _CategoryEditSheet extends ConsumerStatefulWidget {
  const _CategoryEditSheet({this.c});
  final Category? c;

  @override
  ConsumerState<_CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<_CategoryEditSheet> {
  late final TextEditingController _name;
  late int _type;
  late String _icon;
  late int _color;

  bool get _isEdit => widget.c != null;

  @override
  void initState() {
    super.initState();
    final c = widget.c;
    _name = TextEditingController(text: c?.name ?? '');
    _type = c?.type ?? 0;
    _icon = (c?.icon.isNotEmpty ?? false) ? c!.icon : _iconNames.first;
    _color = c?.color ?? 0xFF4DB6AC;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(_isEdit ? '编辑分类' : '新增分类',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _seg('支出', 0),
                const SizedBox(width: 12),
                _seg('收入', 1),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '分类名称',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('图标', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in _iconNames) _iconDot(n),
              ],
            ),
            const SizedBox(height: 14),
            Text('颜色', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _colorChoices) _colorDot(c),
              ],
            ),
            const SizedBox(height: 18),
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _type = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
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

  Widget _iconDot(String name) {
    final selected = _icon == name;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _icon = name);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : const Color(0xFFF2EEEE),
          shape: BoxShape.circle,
        ),
        child: Icon(iconFor(name), size: 20, color: selected ? Colors.white : Colors.black54),
      ),
    );
  }

  Widget _colorDot(Color color) {
    final selected = _color == color.value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _color = color.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Colors.black38, width: 2) : null,
        ),
        child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }

  Widget _saveBtn() {
    return FilledButton.icon(
      onPressed: _save,
      icon: const Icon(Icons.check),
      label: Text(_isEdit ? '更新' : '保存'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _deleteBtn() {
    return OutlinedButton.icon(
      onPressed: _delete,
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('删除'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        foregroundColor: Colors.redAccent,
        side: const BorderSide(color: Colors.redAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入分类名称')));
      return;
    }
    HapticFeedback.mediumImpact();
    final db = ref.read(dbProvider);
    final cat = Category(
      id: widget.c?.id ?? 0,
      name: name,
      icon: _icon,
      color: _color,
      type: _type,
    );
    if (_isEdit) {
      await db.updateCategory(cat);
    } else {
      await db.addCategory(cat);
    }
    bumpTick(ref);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final db = ref.read(dbProvider);
    final count = await db.countTxOfCategory(widget.c!.id);
    final message = count > 0
        ? '该分类下有 $count 条记录，删除会一并删除这些记录。确定删除？'
        : '确定删除该分类？';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分类'),
        content: Text(message),
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
      await db.deleteCategory(widget.c!.id);
      bumpTick(ref);
      if (mounted) Navigator.of(context).pop();
    }
  }
}
