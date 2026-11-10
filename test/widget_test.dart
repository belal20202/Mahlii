import 'package:flutter_test/flutter_test.dart';
import 'package:mahalli/core/theme.dart';

void main() {
  test('الثيم الفاتح والداكن يُبنيان بدون أخطاء', () {
    expect(AppTheme.light().useMaterial3, isTrue);
    expect(AppTheme.dark().useMaterial3, isTrue);
  });
}
