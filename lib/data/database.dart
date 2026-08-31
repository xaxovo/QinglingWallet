import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  Database? _db;
  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'qinglingwallet.db');
    _db = await openDatabase(
        path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'));
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT DEFAULT '',
        color INTEGER DEFAULT 0xFF888888,
        type INTEGER DEFAULT 0,
        sort INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type INTEGER DEFAULT 0,
        categoryId INTEGER NOT NULL,
        note TEXT DEFAULT '',
        ts INTEGER NOT NULL,
        FOREIGN KEY(categoryId) REFERENCES categories(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE recurring_rules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        categoryId INTEGER NOT NULL,
        type INTEGER DEFAULT 0,
        frequency TEXT DEFAULT 'monthly',
        day INTEGER DEFAULT 1,
        note TEXT DEFAULT '',
        enabled INTEGER DEFAULT 1
      )
    ''');
    await _seed(db);
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_rules(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          amount REAL NOT NULL,
          categoryId INTEGER NOT NULL,
          type INTEGER DEFAULT 0,
          frequency TEXT DEFAULT 'monthly',
          day INTEGER DEFAULT 1,
          note TEXT DEFAULT '',
          enabled INTEGER DEFAULT 1
        )
      ''');
    }
  }

  Future<void> _seed(Database db) async {
    final cats = <List<Object>>[
      ['餐饮', 'restaurant', 0xFFFF8A65, 0],
      ['交通', 'directions_car', 0xFF64B5F6, 0],
      ['购物', 'shopping_bag', 0xFF9575CD, 0],
      ['娱乐', 'sports_esports', 0xFF4DB6AC, 0],
      ['日用', 'home', 0xFFFFB74D, 0],
      ['医疗', 'local_hospital', 0xFFF06292, 0],
      ['其他', 'more_horiz', 0xFF9E9E9E, 0],
      ['工资', 'payments', 0xFF81C784, 1],
      ['奖金', 'celebration', 0xFFFFD54F, 1],
      ['红包', 'redeem', 0xFFF48FB1, 1],
    ];
    for (final c in cats) {
      await db.insert('categories', {
        'name': c[0],
        'icon': c[1],
        'color': c[2],
        'type': c[3],
        'sort': 0,
      });
    }
  }

  Future<List<Category>> categories() async {
    final rows = await (await db)
        .query('categories', orderBy: 'type ASC, sort ASC, id ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> addTx(
      double amount, int type, int categoryId, String note, int ts) async {
    return (await db).insert('transactions', {
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'note': note,
      'ts': ts,
    });
  }

  Future<int> updateTx(int id, double amount, int type, int categoryId,
      String note, int ts) async {
    return (await db).update('transactions', {
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'note': note,
      'ts': ts,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTx(int id) async {
    return (await db).delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addCategory(Category c) async {
    return (await db).insert('categories', {
      'name': c.name,
      'icon': c.icon,
      'color': c.color,
      'type': c.type,
      'sort': c.sort,
    });
  }

  Future<int> updateCategory(Category c) async {
    return (await db).update('categories', {
      'name': c.name,
      'icon': c.icon,
      'color': c.color,
      'type': c.type,
      'sort': c.sort,
    }, where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> deleteCategory(int id) async {
    return (await db).delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countTxOfCategory(int categoryId) async {
    final r = await (await db).rawQuery(
        'SELECT COUNT(*) AS c FROM transactions WHERE categoryId = ?',
        [categoryId]);
    return (r.first['c'] as num?)?.toInt() ?? 0;
  }

  // 指定时间范围内某类型各分类合计
  Future<List<Map<String, Object?>>> categoryTotals(
      int type, int startTs, int endTs) async {
    return (await db).rawQuery(
        'SELECT categoryId, SUM(amount) AS total FROM transactions WHERE type = ? AND ts >= ? AND ts < ? GROUP BY categoryId ORDER BY total DESC',
        [type, startTs, endTs]);
  }

  Future<List<Map<String, Object?>>> monthlyTrend() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 5, 1).millisecondsSinceEpoch;
    return (await db).rawQuery(
        "SELECT strftime('%Y-%m', ts/1000, 'unixepoch', 'localtime') AS m, type, SUM(amount) AS s FROM transactions WHERE ts >= ? GROUP BY m, type ORDER BY m",
        [start]);
  }

  // 支持月份范围 + 备注搜索 + 分类/收支筛选
  Future<List<Tx>> txs(
      {int limit = 500,
      int? startTs,
      int? endTs,
      String? q,
      int? catId,
      int? type}) async {
    final where = <String>[];
    final args = <Object>[];
    if (startTs != null) {
      where.add('ts >= ?');
      args.add(startTs);
    }
    if (endTs != null) {
      where.add('ts < ?');
      args.add(endTs);
    }
    if (q != null && q.isNotEmpty) {
      where.add('note LIKE ?');
      args.add('%$q%');
    }
    if (catId != null) {
      where.add('categoryId = ?');
      args.add(catId);
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    final rows = await (await db).query('transactions',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: where.isEmpty ? null : args,
        orderBy: 'ts DESC',
        limit: limit);
    return rows.map(Tx.fromMap).toList();
  }

  Future<double> balance() async {
    final rows = await (await db).rawQuery(
        'SELECT SUM(CASE WHEN type=1 THEN amount ELSE -amount END) AS b FROM transactions');
    final v = rows.first['b'];
    return v == null ? 0.0 : (v as num).toDouble();
  }

  Future<Map<String, double>> monthTotals({int? startTs, int? endTs}) async {
    final s = startTs ??
        DateTime(DateTime.now().year, DateTime.now().month, 1)
            .millisecondsSinceEpoch;
    final e = endTs ??
        DateTime(DateTime.now().year, DateTime.now().month + 1, 1)
            .millisecondsSinceEpoch;
    final rows = await (await db).rawQuery(
        'SELECT type, SUM(amount) AS s FROM transactions WHERE ts >= ? AND ts < ? GROUP BY type',
        [s, e]);
    double income = 0, expense = 0;
    for (final r in rows) {
      final v = (r['s'] as num).toDouble();
      if (r['type'] == 1) {
        income = v;
      } else {
        expense = v;
      }
    }
    return {'income': income, 'expense': expense};
  }

  // ===== 重复记账规则 =====
  Future<List<RecurringRule>> rules() async {
    final rows = await (await db).query('recurring_rules', orderBy: 'id DESC');
    return rows.map(RecurringRule.fromMap).toList();
  }

  Future<int> addRule(RecurringRule r) async {
    return (await db).insert('recurring_rules', {
      'name': r.name,
      'amount': r.amount,
      'categoryId': r.categoryId,
      'type': r.type,
      'frequency': r.frequency,
      'day': r.day,
      'note': r.note,
      'enabled': r.enabled ? 1 : 0,
    });
  }

  Future<int> updateRule(RecurringRule r) async {
    return (await db).update('recurring_rules', {
      'name': r.name,
      'amount': r.amount,
      'categoryId': r.categoryId,
      'type': r.type,
      'frequency': r.frequency,
      'day': r.day,
      'note': r.note,
      'enabled': r.enabled ? 1 : 0,
    }, where: 'id = ?', whereArgs: [r.id]);
  }

  Future<int> deleteRule(int id) async {
    return (await db).delete('recurring_rules', where: 'id = ?', whereArgs: [id]);
  }

  // 判断某规则在当前周期是否已有记录（用于自动补记去重）
  Future<bool> ruleHasTx(
      int categoryId, double amount, int type, String note, int startTs,
      int endTs) async {
    final r = await (await db).rawQuery(
        'SELECT COUNT(*) AS c FROM transactions WHERE categoryId = ? AND amount = ? AND type = ? AND note = ? AND ts >= ? AND ts < ?',
        [categoryId, amount, type, note, startTs, endTs]);
    return ((r.first['c'] as num?)?.toInt() ?? 0) > 0;
  }
}
