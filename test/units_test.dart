import 'package:flutter_test/flutter_test.dart';
import 'package:mahalli/core/units.dart';

void main() {
  test('8 كراتين × 12 = 96 قطعة', () {
    expect(Units.toPieces(cartons: 8, pieces: 0, perCarton: 12), 96);
  });

  test('بعد بيع 5 قطع يبقى 7 كراتين و7 قطع', () {
    expect(Units.format(91, 12), '7 كرتون و7 قطعة');
  });

  test('منتج بدون كارتون', () {
    expect(Units.format(5, 1), '5 قطعة');
  });

  test('تنسيق الدينار', () {
    expect(iqd(1250000), '1,250,000 د.ع');
  });
}
