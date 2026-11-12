import 'product.dart';

class CartLine {
  final Product product;
  final int qty;

  const CartLine({required this.product, required this.qty});

  int get unitPrice => product.salePrice;
  int get total => qty * unitPrice;

  CartLine copyWith({int? qty}) =>
      CartLine(product: product, qty: qty ?? this.qty);
}

class Invoice {
  final int id;
  final String number;
  final String type;
  final String? party;
  final String? userName;
  final int subtotal;
  final int discount;
  final int total;
  final int paid;
  final String? method;
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
  final String unit;
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
  const TodaySummary(this.salesTotal, this.invoiceCount);
}
