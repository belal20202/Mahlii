import 'package:flutter_test/flutter_test.dart';
import 'package:mahalli/features/sales/cart.dart';
import 'package:mahalli/models/product.dart';

void main() {
  const p = Product(
    id: 1,
    name: 'زيت',
    salePrice: 2500,
    costPrice: 2000,
    qtyPieces: 14,
    piecesPerCarton: 12,
  );

  test('لا يسمح بتجاوز المتوفر', () {
    final c = CartNotifier();
    expect(c.add(p, carton: true), isTrue); // 12 قطعة
    expect(c.add(p), isTrue); // 13
    expect(c.add(p), isTrue); // 14
    expect(c.add(p), isFalse); // 15 > 14
  });

  test('سعر الكرتون = سعر القطعة × عدد القطع', () {
    final c = CartNotifier()..add(p, carton: true);
    expect(c.state.first.unitPrice, 30000);
    expect(c.state.first.pieces, 12);
  });

  test('تحويل الوحدة يحسب السعر من جديد', () {
    final c = CartNotifier()..add(p);
    expect(c.switchUnit(0), isTrue);
    expect(c.state.first.carton, isTrue);
    expect(c.state.first.unitPrice, 30000);
  });
}
