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
    _db = await openDatabase(path, version: 2, onCreate: _onCreate,
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
    await _seed(db);
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
        'SELECT COUNT(*) AS c FROM transactions WHERE categoryId = ?', [categoryId]);
    return (r.first['c'] as num?)?.toInt() ?? 0;
  }

  // 本月某类型(0支出/1收入)各分类合计，用于占比环图
  Future<List<Map<String, Object?>>> categoryTotals(
      int type, int monthStart) async {
    return (await db).rawQuery(
        'SELECT categoryId, SUM(amount) AS total FROM transactions WHERE type = ? AND ts >= ? GROUP BY categoryId ORDER BY total DESC',
        [type, monthStart]);
  }

  // 近6个月每月收入/支出，用于趋势折线
  Future<List<Map<String, Object?>>> monthlyTrend() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 5, 1).millisecondsSinceEpoch;
    return (await db).rawQuery(
        "SELECT strftime('%Y-%m', ts/1000, 'unixepoch', 'localtime') AS m, type, SUM(amount) AS s FROM transactions WHERE ts >= ? GROUP BY m, type ORDER BY m",
        [start]);
  }

  Future<List<Tx>> txs({int limit = 300}) async {
    final rows = await (await db)
        .query('transactions', orderBy: 'ts DESC', limit: limit);
    return rows.map(Tx.fromMap).toList();
  }

  Future<double> balance() async {
    final rows = await (await db).rawQuery(
        'SELECT SUM(CASE WHEN type=1 THEN amount ELSE -amount END) AS b FROM transactions');
    final v = rows.first['b'];
    return v == null ? 0.0 : (v as num).toDouble();
  }

  Future<Map<String, double>> monthTotals() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final rows = await (await db).rawQuery(
        'SELECT type, SUM(amount) AS s FROM transactions WHERE ts >= ? GROUP BY type',
        [first]);
    double income = 0, expense = 0;
    for (final r in rows) {
      final s = (r['s'] as num).toDouble();
      if (r['type'] == 1) {
        income = s;
      } else {
        expense = s;
      }
    }
    return {'income': income, 'expense': expense};
  }
}
