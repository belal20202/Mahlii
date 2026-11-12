class Product {
  final int? id;
  final String name;
  final String? barcode;
  final String? internalCode;
  final String? category; // القسم
  final int salePrice;
  final int qtyPieces;
  final int minStock;
  final String? imagePath;

  const Product({
    this.id,
    required this.name,
    this.barcode,
    this.internalCode,
    this.category,
    this.salePrice = 0,
    this.qtyPieces = 0,
    this.minStock = 10,
    this.imagePath,
  });

  bool get isLow => qtyPieces < minStock;

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as int?,
        name: m['name'] as String,
        barcode: m['barcode'] as String?,
        internalCode: m['internal_code'] as String?,
        category: m['category'] as String?,
        salePrice: m['sale_price'] as int,
        qtyPieces: m['qty_pieces'] as int,
        minStock: m['min_stock'] as int,
        imagePath: m['image_path'] as String?,
      );
}

class Stats {
  final int productCount;
  final int shortages;
  const Stats(this.productCount, this.shortages);
}
