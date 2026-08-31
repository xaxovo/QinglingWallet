import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models.dart';
import '../providers.dart';

class DataManageScreen extends ConsumerWidget {
  const DataManageScreen({super.key});

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // 导出 CSV 并分享出去（可存网盘/发其他设备）
  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final db = ref.read(dbProvider);
    final txs = await db.txs(limit: 100000);
    final cats = await db.categories();
    final catName = {for (final c in cats) c.id: c.name};
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/qinglingwallet_export.csv');
    final sb = StringBuffer('金额,类型,分类,备注,时间\n');
    for (final t in txs) {
      sb.writeln(
          '${t.amount},${t.type},${catName[t.categoryId] ?? ''},${t.note},${t.ts}');
    }
    await file.writeAsString(sb.toString());
    await Share.shareXFiles([XFile(file.path)],
        text: '清零记账导出数据');
  }

  // 导入：用文件选择器挑 CSV
  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) {
      _toast(context, '文件不存在');
      return;
    }
    final lines = await file.readAsLines();
    final db = ref.read(dbProvider);
    final cats = await db.categories();
    var catIdByName = {for (final c in cats) c.name: c.id};
    int inserted = 0;
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 5) continue;
      final amount = double.tryParse(parts[0]);
      final type = int.tryParse(parts[1]) ?? 0;
      final catName = parts[2];
      final note = parts.length > 3 ? parts[3] : '';
      final ts = int.tryParse(parts.length > 4 ? parts[4] : '') ??
          DateTime.now().millisecondsSinceEpoch;
      if (amount == null || amount <= 0) continue;
      int cid;
      if (catIdByName.containsKey(catName)) {
        cid = catIdByName[catName]!;
      } else if (catName.isNotEmpty) {
        cid = await db.addCategory(Category(
            id: 0,
            name: catName,
            icon: 'more_horiz',
            color: 0xFF9E9E9E,
            type: type));
        catIdByName[catName] = cid;
      } else {
        continue;
      }
      await db.addTx(amount, type, cid, note, ts);
      inserted++;
    }
    bumpTick(ref);
    _toast(context, '已导入 $inserted 条记录');
  }

  // 备份数据库副本并分享出去
  Future<void> _backup(BuildContext context) async {
    final dir = await getApplicationDocumentsDirectory();
    final src = File('${dir.path}/qinglingwallet.db');
    if (!await src.exists()) {
      _toast(context, '数据库文件不存在');
      return;
    }
    final name =
        'qinglingwallet_backup_${DateTime.now().millisecondsSinceEpoch}.db';
    final dst = File('${dir.path}/$name');
    await src.copy(dst.path);
    await Share.shareXFiles([XFile(dst.path)], text: '清零记账备份');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据管理'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(context, ref, Icons.upload_file, '导出数据（CSV）',
              '导出后可分享到其他设备', () => _export(context, ref)),
          _tile(context, ref, Icons.download, '导入数据（CSV）',
              '从 CSV 文件恢复数据', () => _import(context, ref)),
          _tile(context, ref, Icons.archive, '一键备份',
              '备份数据库并分享', () => _backup(context)),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.15),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      ),
    );
  }
}
