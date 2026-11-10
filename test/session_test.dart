import 'package:flutter_test/flutter_test.dart';
import 'package:mahalli/models/session.dart';

void main() {
  test('نهاية الاشتراك = البداية + الأيام', () {
    final s = Session(
      uid: 'u',
      storeId: 's',
      storeName: 'محل',
      userName: 'x',
      role: 'owner',
      plan: 'شهري',
      start: DateTime(2026, 11, 1),
      planDays: 30,
      maxUsers: 3,
    );
    expect(s.end, DateTime(2026, 12, 1));
    expect(s.roleLabel, 'مالك المحل');
    expect(s.canManageStaff, isTrue);
  });
}
