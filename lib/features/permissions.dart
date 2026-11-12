import '../models/session.dart';

/// الموظف (cashier) يبيع ويضيف البضاعة والمنتجات.
bool canSell(Session? s) =>
    s != null && const ['owner', 'manager', 'cashier'].contains(s.role);

bool canPurchase(Session? s) =>
    s != null &&
    const ['owner', 'manager', 'cashier', 'warehouse'].contains(s.role);

bool canSeeProfit(Session? s) =>
    s != null && const ['owner', 'manager'].contains(s.role);
