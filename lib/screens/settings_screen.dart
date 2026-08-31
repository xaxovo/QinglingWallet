import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'category_manage_screen.dart';
import 'data_manage_screen.dart';
import 'recurring_manage_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            // 应用详情直接显示（关于页不折叠）
            Container(
              padding: const EdgeInsets.all(26),
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
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.asset('assets/about_logo.png',
                          fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('清零记账',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snap) => Text(
                      'v${snap.data?.version ?? '0.2.0'}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('简洁易用 · 高度个人化的记账 App',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.82), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _entry(
              context,
              Icons.category_outlined,
              '分类管理',
              '自定义收 / 支分类',
              () => _push(context, const CategoryManageScreen()),
            ),
            _entry(
              context,
              Icons.event_repeat_outlined,
              '自动记账',
              '按周 / 月 / 年自动补记',
              () => _push(context, const RecurringManageScreen()),
            ),
            _entry(
              context,
              Icons.storage_outlined,
              '数据管理',
              '导出 / 导入 / 一键备份',
              () => _push(context, const DataManageScreen()),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text('BG2HCB 制造 · QinglingWallet',
                  style: TextStyle(color: Colors.black38, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entry(BuildContext context, IconData icon, String title,
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
