class Category {
  final int id;
  final String name;
  final String icon;
  final int color;
  final int type; // 0 支出, 1 收入
  final int sort;

  const Category({
    required this.id,
    required this.name,
    this.icon = '',
    this.color = 0xFF888888,
    required this.type,
    this.sort = 0,
  });

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as int,
        name: m['name'] as String,
        icon: m['icon'] as String? ?? '',
        color: m['color'] as int? ?? 0xFF888888,
        type: m['type'] as int? ?? 0,
        sort: m['sort'] as int? ?? 0,
      );
}

class Tx {
  final int id;
  final double amount;
  final int type; // 0 支出, 1 收入
  final int categoryId;
  final String note;
  final int ts; // epoch millis

  const Tx({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note = '',
    required this.ts,
  });

  factory Tx.fromMap(Map<String, dynamic> m) => Tx(
        id: m['id'] as int,
        amount: (m['amount'] as num).toDouble(),
        type: m['type'] as int? ?? 0,
        categoryId: m['categoryId'] as int,
        note: m['note'] as String? ?? '',
        ts: m['ts'] as int,
      );
}
