import '../models/session.dart';

bool canSell(Session? s) =>
    s != null && const ['owner', 'manager', 'cashier'].contains(s.role);

bool canPurchase(Session? s) =>
    s != null && const ['owner', 'manager', 'warehouse'].contains(s.role);

bool canSeeProfit(Session? s) =>
    s != null && const ['owner', 'manager'].contains(s.role);
