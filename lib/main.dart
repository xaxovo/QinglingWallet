import 'package:flutter/material.dart';

void main() => runApp(const QinglingWallet());

class QinglingWallet extends StatelessWidget {
  const QinglingWallet({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2AB8A6));
    return MaterialApp(
      title: '清零记账',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF4F7F9),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _Header(),
              SizedBox(height: 20),
              _BalanceCard(),
              SizedBox(height: 20),
              _QuickAddRow(),
              SizedBox(height: 20),
              Expanded(child: _RecentList()),
            ],
          ),
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
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.pets, color: Colors.white),
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
  const _BalanceCard();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.75)],
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
          Text('本月余额',
              style: TextStyle(color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 8),
          const Text('¥ 12,480.00',
              style: TextStyle(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat('本月支出', '¥ 3,520.00'),
              const SizedBox(width: 24),
              _miniStat('本月收入', '¥ 6,800.00'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _QuickAddRow extends StatelessWidget {
  const _QuickAddRow();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('记一笔'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _chip(Icons.restaurant, '餐饮'),
        const SizedBox(width: 8),
        _chip(Icons.shopping_bag, '购物'),
        const SizedBox(width: 8),
        _chip(Icons.directions_car, '交通'),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList();
  @override
  Widget build(BuildContext context) {
    final items = [
      ('餐饮', '午餐 · 食堂', '-¥25.00',
          Icons.ramen_dining, const Color(0xFFFF8A65)),
      ('交通', '地铁通勤', '-¥4.00',
          Icons.directions_transit, const Color(0xFF64B5F6)),
      ('购物', '超市采购', '-¥86.40',
          Icons.shopping_cart, const Color(0xFF9575CD)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('最近记录',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            TextButton(onPressed: () {}, child: const Text('查看全部')),
          ],
        ),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = items[i];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                color: Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: e.$5.withOpacity(0.15),
                    child: Icon(e.$4, color: e.$5),
                  ),
                  title: Text(e.$1,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(e.$2),
                  trailing: Text(e.$3,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
