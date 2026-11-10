import 'product.dart';

class CartLine {
  final Product product;
  final int qty;
  final bool carton;
  final int unitPrice; // سعر الوحدة المختارة (قطعة أو كرتون)

  const CartLine({
    required this.product,
    required this.qty,
    required this.carton,
    required this.unitPrice,
  });

  int get _per => product.piecesPerCarton < 1 ? 1 : product.piecesPerCarton;
  int get perUnit => carton ? _per : 1;
  int get pieces => qty * perUnit;
  int get total => qty * unitPrice;
  int get costPerPiece => (unitPrice / perUnit).round();

  CartLine copyWith({int? qty, bool? carton, int? unitPrice}) => CartLine(
        product: product,
        qty: qty ?? this.qty,
        carton: carton ?? this.carton,
        unitPrice: unitPrice ?? this.unitPrice,
      );

  CartLine switchedUnit() {
    final piecePrice = unitPrice / perUnit;
    final nc = !carton;
    return CartLine(
      product: product,
      qty: qty,
      carton: nc,
      unitPrice: (piecePrice * (nc ? _per : 1)).round(),
    );
  }
}

class Invoice {
  final int id;
  final String number;
  final String type; // sale | purchase
  final String? party;
  final String? userName;
  final int subtotal;
  final int discount;
  final int total;
  final int paid;
  final String? method; // cash | credit | partial
  final String status; // completed | returned
  final DateTime createdAt;

  const Invoice({
    required this.id,
    required this.number,
    required this.type,
    this.party,
    this.userName,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paid,
    this.method,
    required this.status,
    required this.createdAt,
  });

  int get remaining => total - paid;
  bool get isSale => type == 'sale';

  static const methodLabels = {
    'cash': 'نقدي',
    'credit': 'آجل',
    'partial': 'دفع جزئي',
  };

  factory Invoice.fromMap(Map<String, Object?> m) => Invoice(
        id: m['id'] as int,
        number: m['number'] as String,
        type: m['type'] as String,
        party: m['party'] as String?,
        userName: m['user_name'] as String?,
        subtotal: m['subtotal'] as int,
        discount: m['discount'] as int,
        total: m['total'] as int,
        paid: m['paid'] as int,
        method: m['payment_method'] as String?,
        status: m['status'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}

class InvoiceItem {
  final String name;
  final String unit; // piece | carton
  final int qty;
  final int unitPrice;

  const InvoiceItem({
    required this.name,
    required this.unit,
    required this.qty,
    required this.unitPrice,
  });

  int get total => qty * unitPrice;

  factory InvoiceItem.fromMap(Map<String, Object?> m) => InvoiceItem(
        name: m['name'] as String,
        unit: m['unit'] as String,
        qty: m['qty'] as int,
        unitPrice: m['unit_price'] as int,
      );
}

class TodaySummary {
  final int salesTotal;
  final int invoiceCount;
  final int profit;
  const TodaySummary(this.salesTotal, this.invoiceCount, this.profit);
}
