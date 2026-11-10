import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../models/invoice.dart';

class InsufficientStockException implements Exception {
  final String productName;
  InsufficientStockException(this.productName);
}

class InvoiceRepository {
  int get _now => DateTime.now().millisecondsSinceEpoch;

  static int _clamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

  static String _opId() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<int> _next(DatabaseExecutor ex, String key) async {
    final r = await ex.query('counters', where: 'key = ?', whereArgs: [key]);
    final n = r.isEmpty ? 1 : (r.first['value'] as int) + 1;
    await ex.insert('counters', {'key': key, 'value': n},
        conflictAlgorithm: ConflictAlgorithm.replace);
    return n;
  }

  Future<void> _audit(DatabaseExecutor ex, String action, int? id, String d) =>
      ex.insert('audit_log', {
        'action': action,
        'entity': 'invoice',
        'entity_id': id,
        'details': d,
        'created_at': _now,
      });

  // ---------------- البيع ----------------
  Future<Invoice> createSale({
    required List<CartLine> lines,
    required int discount,
    required String method, // cash | credit | partial
    required int paid,
    String? customer,
    required String userName,
  }) async {
    final db = await AppDb.get();
    return db.transaction((txn) async {
      final need = <int, int>{};
      for (final l in lines) {
        need[l.product.id!] = (need[l.product.id!] ?? 0) + l.pieces;
      }
      final cost = <int, int>{};
      for (final e in need.entries) {
        final r = await txn.query('products',
            columns: ['qty_pieces', 'name', 'cost_price'],
            where: 'id = ? AND deleted = 0',
            whereArgs: [e.key]);
        if (r.isEmpty) throw StateError('product missing');
        if ((r.first['qty_pieces'] as int) < e.value) {
          throw InsufficientStockException(r.first['name'] as String);
        }
        cost[e.key] = r.first['cost_price'] as int;
      }

      final subtotal = lines.fold<int>(0, (s, l) => s + l.total);
      final disc = _clamp(discount, 0, subtotal);
      final total = subtotal - disc;
      final paidAmt = method == 'cash'
          ? total
          : (method == 'credit' ? 0 : _clamp(paid, 0, total));
      var cogs = 0;
      for (final l in lines) {
        cogs += l.pieces * cost[l.product.id!]!;
      }

      final n = await _next(txn, 'sale');
      final number = 'INV-${n.toString().padLeft(6, '0')}';
      final m = <String, Object?>{
        'op_id': _opId(),
        'number': number,
        'type': 'sale',
        'party': (customer == null || customer.trim().isEmpty)
            ? null
            : customer.trim(),
        'user_name': userName,
        'subtotal': subtotal,
        'discount': disc,
        'total': total,
        'paid': paidAmt,
        'payment_method': method,
        'cogs': cogs,
        'status': 'completed',
        'created_at': _now,
      };
      final id = await txn.insert('invoices', m);

      for (final l in lines) {
        await txn.insert('invoice_items', {
          'invoice_id': id,
          'product_id': l.product.id,
          'name': l.product.name,
          'unit': l.carton ? 'carton' : 'piece',
          'qty': l.qty,
          'pieces_per_unit': l.perUnit,
          'unit_price': l.unitPrice,
          'unit_cost': cost[l.product.id!]!,
        });
      }
      for (final e in need.entries) {
        await txn.rawUpdate(
            'UPDATE products SET qty_pieces = qty_pieces - ?, updated_at = ? WHERE id = ?',
            [e.value, _now, e.key]);
        await txn.insert('stock_movements', {
          'product_id': e.key,
          'type': 'sale',
          'delta_pieces': -e.value,
          'note': number,
          'created_at': _now,
        });
      }
      await _audit(txn, 'sale', id, '$number / $total');
      return Invoice.fromMap({...m, 'id': id});
    });
  }

  // ---------------- الشراء ----------------
  Future<Invoice> createPurchase({
    required List<CartLine> lines,
    required int discount,
    required int paid,
    required String supplier,
    required String userName,
  }) async {
    final db = await AppDb.get();
    return db.transaction((txn) async {
      final subtotal = lines.fold<int>(0, (s, l) => s + l.total);
      final disc = _clamp(discount, 0, subtotal);
      final total = subtotal - disc;
      final paidAmt = _clamp(paid, 0, total);

      final n = await _next(txn, 'purchase');
      final number = 'PUR-${n.toString().padLeft(6, '0')}';
      final m = <String, Object?>{
        'op_id': _opId(),
        'number': number,
        'type': 'purchase',
        'party': supplier.trim(),
        'user_name': userName,
        'subtotal': subtotal,
        'discount': disc,
        'total': total,
        'paid': paidAmt,
        'payment_method': paidAmt >= total ? 'cash' : 'partial',
        'cogs': 0,
        'status': 'completed',
        'created_at': _now,
      };
      final id = await txn.insert('invoices', m);

      for (final l in lines) {
        await txn.insert('invoice_items', {
          'invoice_id': id,
          'product_id': l.product.id,
          'name': l.product.name,
          'unit': l.carton ? 'carton' : 'piece',
          'qty': l.qty,
          'pieces_per_unit': l.perUnit,
          'unit_price': l.unitPrice,
          'unit_cost': l.costPerPiece,
        });
        if (l.costPerPiece > 0) {
          await txn.rawUpdate(
              'UPDATE products SET qty_pieces = qty_pieces + ?, cost_price = ?, updated_at = ? WHERE id = ?',
              [l.pieces, l.costPerPiece, _now, l.product.id]);
        } else {
          await txn.rawUpdate(
              'UPDATE products SET qty_pieces = qty_pieces + ?, updated_at = ? WHERE id = ?',
              [l.pieces, _now, l.product.id]);
        }
        await txn.insert('stock_movements', {
          'product_id': l.product.id,
          'type': 'purchase',
          'delta_pieces': l.pieces,
          'note': number,
          'created_at': _now,
        });
      }
      await _audit(txn, 'purchase', id, '$number / $total');
      return Invoice.fromMap({...m, 'id': id});
    });
  }

  // ---------------- إرجاع كامل ----------------
  Future<void> returnSale(int invoiceId, String userName) async {
    final db = await AppDb.get();
    await db.transaction((txn) async {
      final r = await txn.query('invoices',
          where: 'id = ?', whereArgs: [invoiceId]);
      if (r.isEmpty) throw StateError('missing');
      if (r.first['type'] != 'sale' || r.first['status'] != 'completed') {
        throw StateError('not returnable');
      }
      final number = r.first['number'] as String;
      final items = await txn.query('invoice_items',
          where: 'invoice_id = ?', whereArgs: [invoiceId]);
      for (final it in items) {
        final pieces = (it['qty'] as int) * (it['pieces_per_unit'] as int);
        await txn.rawUpdate(
            'UPDATE products SET qty_pieces = qty_pieces + ?, updated_at = ? WHERE id = ?',
            [pieces, _now, it['product_id']]);
        await txn.insert('stock_movements', {
          'product_id': it['product_id'],
          'type': 'return',
          'delta_pieces': pieces,
          'note': number,
          'created_at': _now,
        });
      }
      await txn.update('invoices', {'status': 'returned'},
          where: 'id = ?', whereArgs: [invoiceId]);
      await _audit(txn, 'return', invoiceId, '$number by $userName');
    });
  }

  // ---------------- الاستعلامات ----------------
  Future<List<Invoice>> list(String type,
      {String query = '', int limit = 200}) async {
    final db = await AppDb.get();
    final where = StringBuffer('type = ?');
    final args = <Object?>[type];
    if (query.trim().isNotEmpty) {
      where.write(' AND (number LIKE ? OR party LIKE ?)');
      args.addAll(['%${query.trim()}%', '%${query.trim()}%']);
    }
    final rows = await db.query('invoices',
        where: where.toString(),
        whereArgs: args,
        orderBy: 'created_at DESC',
        limit: limit);
    return rows.map(Invoice.fromMap).toList();
  }

  Future<List<InvoiceItem>> items(int invoiceId) async {
    final db = await AppDb.get();
    final rows = await db.query('invoice_items',
        where: 'invoice_id = ?', whereArgs: [invoiceId], orderBy: 'id');
    return rows.map(InvoiceItem.fromMap).toList();
  }

  Future<TodaySummary> todaySummary() async {
    final db = await AppDb.get();
    final n = DateTime.now();
    final start = DateTime(n.year, n.month, n.day).millisecondsSinceEpoch;
    final r = await db.rawQuery('''
      SELECT COUNT(*) AS c,
             COALESCE(SUM(total), 0) AS t,
             COALESCE(SUM(total - cogs), 0) AS p
      FROM invoices
      WHERE type = 'sale' AND status = 'completed' AND created_at >= ?''',
        [start]);
    final row = r.first;
    return TodaySummary((row['t'] as num).toInt(), (row['c'] as num).toInt(),
        (row['p'] as num).toInt());
  }
}
