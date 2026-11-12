import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../auth/auth_providers.dart';
import '../invoices/invoices_screen.dart';
import '../permissions.dart';
import '../purchases/purchase_screen.dart';
import '../purchases/receipts_log_screen.dart';
import '../staff/staff_screen.dart';
import '../subscription/subscription_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bootProvider).valueOrNull?.session;
    void go(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (s != null)
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppColors.mint,
                  child: Icon(Icons.person, color: AppColors.emerald)),
              title: Text(s.userName),
              subtitle: Text('${s.storeName}  •  ${s.roleLabel}'),
            ),
          ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('فواتير المبيعات'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => go(const InvoicesScreen()),
        ),
        if (canPurchase(s)) ...[
          ListTile(
            leading: const Icon(Icons.inventory_outlined),
            title: const Text('إضافة بضاعة'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => go(const PurchaseScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('سجل المشتريات والإدخال'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => go(const ReceiptsLogScreen()),
          ),
        ],
        ListTile(
          leading: const Icon(Icons.workspace_premium_outlined),
          title: const Text('اشتراكي'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => go(const SubscriptionScreen()),
        ),
        if (s != null && s.canManageStaff)
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('الموظفون'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => go(const StaffScreen()),
          ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('حول محلي'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => go(const AboutScreen()),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.danger),
          title: const Text('تسجيل الخروج'),
          onTap: () => ref.read(authServiceProvider).logout(),
        ),
      ],
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _AboutBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_rounded, size: 72, color: AppColors.emerald),
            SizedBox(height: 12),
            Text('محلي – Mahalli',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('نظام إدارة المحلات والمخازن الذكي'),
            SizedBox(height: 24),
            Text('المطور: بلال النعيمي'),
            Text('Developer: Belal Alnaimi'),
            SizedBox(height: 16),
            Text('صنع في العراق',
                style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            Text('Made in Iraq', style: TextStyle(color: AppColors.gold)),
            SizedBox(height: 16),
            Text('الإصدار 1.0.0'),
          ],
        ),
      ),
    );
  }
}

class _AboutBar extends StatelessWidget implements PreferredSizeWidget {
  const _AboutBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AppBar(title: const Text('حول محلي'));
}
