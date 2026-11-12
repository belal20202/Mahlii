import 'package:flutter_test/flutter_test.dart';
import 'package:mahalli/features/sales/cart.dart';
import 'package:mahalli/models/product.dart';

void main() {
  const p = Product(id: 1, name: 'زيت', salePrice: 2500, qtyPieces: 3);

  test('لا يسمح بتجاوز المتوفر', () {
    final c = CartNotifier();
    expect(c.add(p), isTrue);
    expect(c.add(p), isTrue);
    expect(c.add(p), isTrue);
    expect(c.add(p), isFalse);
  });

  test('الإجمالي = السعر × الكمية', () {
    final c = CartNotifier()
      ..add(p)
      ..add(p);
    expect(c.state.first.total, 5000);
  });

  test('تعديل الكمية ضمن المتوفر فقط', () {
    final c = CartNotifier()..add(p);
    expect(c.setQty(0, 3), isTrue);
    expect(c.setQty(0, 4), isFalse);
    expect(c.setQty(0, 0), isFalse);
  });
}
