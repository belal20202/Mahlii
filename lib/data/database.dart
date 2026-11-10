import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static Database? _db;

  static Future<Database> get() async => _db ??= await _open();

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'mahalli.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, v) async {
        await _createV1(db);
        await _createV2(db);
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) await _createV2(db);
      },
    );
  }

  static Future<void> _createV1(Database db) async {
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
  }

  static Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        op_id TEXT NOT NULL UNIQUE,
        number TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        party TEXT,
        user_name TEXT,
        subtotal INTEGER NOT NULL,
        discount INTEGER NOT NULL DEFAULT 0,
        total INTEGER NOT NULL,
        paid INTEGER NOT NULL,
        payment_method TEXT,
        cogs INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'completed',
        created_at INTEGER NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX ix_invoices_created ON invoices(created_at)');
    await db.execute('''
      CREATE TABLE invoice_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        qty INTEGER NOT NULL,
        pieces_per_unit INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        unit_cost INTEGER NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX ix_items_invoice ON invoice_items(invoice_id)');
    await db.execute('''
      CREATE TABLE counters(
        key TEXT PRIMARY KEY,
        value INTEGER NOT NULL
      )''');
  }
}
