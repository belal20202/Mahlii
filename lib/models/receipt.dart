import 'product.dart';

class ReceiptLine {
  final Product product;
  final int qty;
  const ReceiptLine({required this.product, required this.qty});
}

class Receipt {
  final int id;
  final String number;
  final int itemsCount;
  final int totalPieces;
  const Receipt({
    required this.id,
    required this.number,
    required this.itemsCount,
    required this.totalPieces,
  });
}

class ReceiptItem {
  final String name;
  final int qty;
  const ReceiptItem({required this.name, required this.qty});
}

/// سطر في سجل المشتريات والإدخال: kind = receipt | new | adjust
class LogEntry {
  final String kind;
  final String title;
  final String subtitle;
  final int pieces;
  final String? userName;
  final DateTime time;
  final int? receiptId;

  const LogEntry({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.pieces,
    required this.time,
    this.userName,
    this.receiptId,
  });
}
