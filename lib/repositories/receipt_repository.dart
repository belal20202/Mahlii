import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../models/receipt.dart';

/// إدخال البضاعة (المشتريات): يزيد المخزون ويسجل رقماً في السجل، بدون فاتورة.
class ReceiptRepository {
  int get _now => DateTime.now().millisecondsSinceEpoch;

  Future<int> _next(DatabaseExecutor ex, String key) async {
    final r = await ex.query('counters', where: 'key = ?', whereArgs: [key]);
    final n = r.isEmpty ? 1 : (r.first['value'] as int) + 1;
    await ex.insert('counters', {'key': key, 'value': n},
        conflictAlgorithm: ConflictAlgorithm.replace);
    return n;
  }

  Future<Receipt> create({
    required List<ReceiptLine> lines,
    required String userName,
  }) async {
    final db = await AppDb.get();
    return db.transaction((txn) async {
      final merged = <int, int>{};
      for (final l in lines) {
        merged[l.product.id!] = (merged[l.product.id!] ?? 0) + l.qty;
      }
      final total = merged.values.fold<int>(0, (a, b) => a + b);
      final n = await _next(txn, 'receipt');
      final number = 'PUR-${n.toString().padLeft(6, '0')}';
      final id = await txn.insert('receipts', {
        'number': number,
        'user_name': userName,
        'items_count': merged.length,
        'total_pieces': total,
        'created_at': _now,
      });
      for (final e in merged.entries) {
        final r = await txn.query('products',
            columns: ['name'],
            where: 'id = ? AND deleted = 0',
            whereArgs: [e.key]);
        if (r.isEmpty) throw StateError('product missing');
        await txn.insert('receipt_items', {
          'receipt_id': id,
          'product_id': e.key,
          'name': r.first['name'] as String,
          'qty': e.value,
        });
        await txn.rawUpdate(
            'UPDATE products SET qty_pieces = qty_pieces + ?, updated_at = ? WHERE id = ?',
            [e.value, _now, e.key]);
        await txn.insert('stock_movements', {
          'product_id': e.key,
          'type': 'purchase',
          'delta_pieces': e.value,
          'note': number,
          'user_name': userName,
          'created_at': _now,
        });
      }
      await txn.insert('audit_log', {
        'action': 'receipt',
        'entity': 'receipt',
        'entity_id': id,
        'details': '$number / $total',
        'created_at': _now,
      });
      return Receipt(
          id: id,
          number: number,
          itemsCount: merged.length,
          totalPieces: total);
    });
  }

  Future<List<ReceiptItem>> items(int receiptId) async {
    final db = await AppDb.get();
    final rows = await db.query('receipt_items',
        where: 'receipt_id = ?', whereArgs: [receiptId], orderBy: 'id');
    return rows
        .map((r) =>
            ReceiptItem(name: r['name'] as String, qty: r['qty'] as int))
        .toList();
  }

  Future<List<LogEntry>> log({int limit = 300}) async {
    final db = await AppDb.get();
    final rec = await db.query('receipts',
        orderBy: 'created_at DESC', limit: limit);
    final mv = await db.rawQuery('''
      SELECT m.type, m.delta_pieces, m.user_name, m.created_at, p.name
      FROM stock_movements m
      JOIN products p ON p.id = m.product_id
      WHERE m.type IN ('initial', 'adjust')
      ORDER BY m.created_at DESC
      LIMIT ?''', [limit]);
    final all = <LogEntry>[
      for (final r in rec)
        LogEntry(
          kind: 'receipt',
          title: r['number'] as String,
          subtitle: '${r['items_count']} صنف',
          pieces: r['total_pieces'] as int,
          userName: r['user_name'] as String?,
          time: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
          receiptId: r['id'] as int,
        ),
      for (final m in mv)
        LogEntry(
          kind: m['type'] == 'initial' ? 'new' : 'adjust',
          title: m['type'] == 'initial' ? 'منتج جديد' : 'تعديل كمية',
          subtitle: m['name'] as String,
          pieces: m['delta_pieces'] as int,
          userName: m['user_name'] as String?,
          time: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        ),
    ];
    all.sort((a, b) => b.time.compareTo(a.time));
    return all.length > limit ? all.sublist(0, limit) : all;
  }
}
