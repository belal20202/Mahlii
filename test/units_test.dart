import 'package:flutter_test/flutter_test.dart';
import 'package:mahalli/core/units.dart';

void main() {
  test('تنسيق الدينار', () {
    expect(iqd(1250000), '1,250,000 د.ع');
    expect(iqd(500), '500 د.ع');
  });
}
