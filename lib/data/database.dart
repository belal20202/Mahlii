import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static Database? _db;

  static Future<Database> get() async => _db ??= await _open();

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'mahalli.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            barcode TEXT,
            internal_code TEXT,
            category TEXT,
            manufacturer TEXT,
            cost_price INTEGER NOT NULL DEFAULT 0,
            sale_price INTEGER NOT NULL DEFAULT 0,
            qty_pieces INTEGER NOT NULL DEFAULT 0,
            pieces_per_carton INTEGER NOT NULL DEFAULT 1,
            min_stock INTEGER NOT NULL DEFAULT 10,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0
          )''');
        // باركود فريد للمنتجات غير المحذوفة فقط، ويسمح بمنتجات بلا باركود
        await db.execute('''
          CREATE UNIQUE INDEX ux_products_barcode
          ON products(barcode) WHERE barcode IS NOT NULL AND deleted = 0''');
        await db.execute('CREATE INDEX ix_products_name ON products(name)');
        await db.execute('''
          CREATE TABLE stock_movements(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            type TEXT NOT NULL,
            delta_pieces INTEGER NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE audit_log(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT NOT NULL,
            entity TEXT NOT NULL,
            entity_id INTEGER,
            details TEXT,
            created_at INTEGER NOT NULL
          )''');
      },
    );
  }
}
