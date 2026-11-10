class Product {
  final int? id;
  final String name;
  final String? barcode;
  final String? internalCode;
  final String? category;
  final String? manufacturer;
  final int costPrice;
  final int salePrice;
  final int qtyPieces;
  final int piecesPerCarton;
  final int minStock;

  const Product({
    this.id,
    required this.name,
    this.barcode,
    this.internalCode,
    this.category,
    this.manufacturer,
    this.costPrice = 0,
    this.salePrice = 0,
    this.qtyPieces = 0,
    this.piecesPerCarton = 1,
    this.minStock = 10,
  });

  bool get isLow => qtyPieces < minStock;
  int get profitPerPiece => salePrice - costPrice;
  double get marginPercent =>
      costPrice == 0 ? 0 : (profitPerPiece / costPrice) * 100;

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as int?,
        name: m['name'] as String,
        barcode: m['barcode'] as String?,
        internalCode: m['internal_code'] as String?,
        category: m['category'] as String?,
        manufacturer: m['manufacturer'] as String?,
        costPrice: m['cost_price'] as int,
        salePrice: m['sale_price'] as int,
        qtyPieces: m['qty_pieces'] as int,
        piecesPerCarton: m['pieces_per_carton'] as int,
        minStock: m['min_stock'] as int,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'barcode': barcode,
        'internal_code': internalCode,
        'category': category,
        'manufacturer': manufacturer,
        'cost_price': costPrice,
        'sale_price': salePrice,
        'qty_pieces': qtyPieces,
        'pieces_per_carton': piecesPerCarton,
        'min_stock': minStock,
      };
}

class Stats {
  final int productCount;
  final int stockValue;
  final int shortages;
  const Stats(this.productCount, this.stockValue, this.shortages);
}
