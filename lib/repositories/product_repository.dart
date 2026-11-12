import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../models/product.dart';

class DuplicateBarcodeException implements Exception {}

class ProductRepository {
  int get _now => DateTime.now().millisecondsSinceEpoch;

  Future<List<Product>> search(
    String query, {
    bool lowOnly = false,
    int limit = 500,
  }) async {
    final db = await AppDb.get();
    final where = StringBuffer('deleted = 0');
    final args = <Object?>[];
    if (query.trim().isNotEmpty) {
      where.write(
          ' AND (name LIKE ? OR barcode LIKE ? OR internal_code LIKE ? OR category LIKE ?)');
      final q = '%${query.trim()}%';
      args.addAll([q, q, q, q]);
    }
    if (lowOnly) where.write(' AND qty_pieces < min_stock');
    final rows = await db.query(
      'products',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'name COLLATE NOCASE',
      limit: limit,
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> findByBarcode(String code) async {
    final db = await AppDb.get();
    final rows = await db.query(
      'products',
      where: 'barcode = ? AND deleted = 0',
      whereArgs: [code.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  Future<List<String>> sections() async {
    final db = await AppDb.get();
    final r = await db.rawQuery('''
      SELECT DISTINCT category FROM products
      WHERE deleted = 0 AND category IS NOT NULL AND category != ''
      ORDER BY category COLLATE NOCASE''');
    return r.map((e) => e['category'] as String).toList();
  }

  Map<String, Object?> _fields(Product p) => {
        'name': p.name,
        'barcode': p.barcode,
        'category': p.category,
        'sale_price': p.salePrice,
        'qty_pieces': p.qtyPieces,
        'min_stock': p.minStock,
        'image_path': p.imagePath,
      };

  Future<int> insert(Product p, {String? userName}) async {
    final db = await AppDb.get();
    try {
      return await db.transaction((txn) async {
        final map = _fields(p)
          ..['created_at'] = _now
          ..['updated_at'] = _now
          ..['deleted'] = 0;
        final id = await txn.insert('products', map);
        await txn.update(
          'products',
          {'internal_code': 'P${id.toString().padLeft(5, '0')}'},
          where: 'id = ?',
          whereArgs: [id],
        );
        await txn.insert('stock_movements', {
          'product_id': id,
          'type': 'initial',
          'delta_pieces': p.qtyPieces,
          'note': 'منتج جديد',
          'user_name': userName,
          'created_at': _now,
        });
        await _audit(txn, 'create', id, p.name);
        return id;
      });
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw DuplicateBarcodeException();
      rethrow;
    }
  }

  Future<void> update(Product p, {String? userName}) async {
    final db = await AppDb.get();
    try {
      await db.transaction((txn) async {
        final old = await txn.query('products',
            columns: ['qty_pieces'], where: 'id = ?', whereArgs: [p.id]);
        final oldQty = old.isEmpty ? 0 : old.first['qty_pieces'] as int;
        final map = _fields(p)..['updated_at'] = _now;
        await txn.update('products', map, where: 'id = ?', whereArgs: [p.id]);
        if (oldQty != p.qtyPieces) {
          await txn.insert('stock_movements', {
            'product_id': p.id,
            'type': 'adjust',
            'delta_pieces': p.qtyPieces - oldQty,
            'note': 'تعديل يدوي',
            'user_name': userName,
            'created_at': _now,
          });
        }
        await _audit(txn, 'update', p.id, p.name);
      });
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw DuplicateBarcodeException();
      rethrow;
    }
  }

  /// حذف منطقي مع الاحتفاظ بالسجل
  Future<void> softDelete(int id, String name) async {
    final db = await AppDb.get();
    await db.transaction((txn) async {
      await txn.update('products', {'deleted': 1, 'updated_at': _now},
          where: 'id = ?', whereArgs: [id]);
      await _audit(txn, 'delete', id, name);
    });
  }

  Future<Stats> stats() async {
    final db = await AppDb.get();
    final r = await db.rawQuery('''
      SELECT COUNT(*) AS c,
             COALESCE(SUM(CASE WHEN qty_pieces < min_stock THEN 1 ELSE 0 END), 0) AS s
      FROM products WHERE deleted = 0''');
    final row = r.first;
    return Stats((row['c'] as num).toInt(), (row['s'] as num).toInt());
  }

  Future<void> _audit(
      DatabaseExecutor ex, String action, int? id, String? details) {
    return ex.insert('audit_log', {
      'action': action,
      'entity': 'product',
      'entity_id': id,
      'details': details,
      'created_at': _now,
    });
  }
}
