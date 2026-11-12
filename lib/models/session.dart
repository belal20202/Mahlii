import '../core/server_clock.dart';

class Session {
  final String uid;
  final String storeId;
  final String storeName;
  final String userName;
  final String role; // owner | manager | cashier (موظف) | warehouse
  final String plan;
  final DateTime start;
  final int planDays;
  final int maxUsers;

  const Session({
    required this.uid,
    required this.storeId,
    required this.storeName,
    required this.userName,
    required this.role,
    required this.plan,
    required this.start,
    required this.planDays,
    required this.maxUsers,
  });

  DateTime get end => start.add(Duration(days: planDays));

  bool get isActive => ServerClock.now().isBefore(end);
  bool get canWrite => isActive;

  int get daysLeft {
    final d = end.difference(ServerClock.now());
    if (d.isNegative) return 0;
    return (d.inHours / 24).ceil();
  }

  bool get canManageStaff => role == 'owner' || role == 'manager';
  bool get isOwner => role == 'owner';

  static const roleLabels = {
    'owner': 'مالك المحل',
    'manager': 'المدير',
    'cashier': 'موظف',
    'warehouse': 'موظف',
  };

  String get roleLabel => roleLabels[role] ?? role;
}
