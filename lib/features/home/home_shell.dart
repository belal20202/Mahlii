import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sound_service.dart';
import '../../core/theme.dart';
import '../../core/units.dart';
import '../../models/session.dart';
import '../auth/auth_providers.dart';
import '../invoices/invoices_screen.dart';
import '../permissions.dart';
import '../products/product_form.dart';
import '../products/products_screen.dart';
import '../providers.dart';
import '../purchases/purchase_screen.dart';
import '../sales/pos_screen.dart';
import '../settings/more_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  DateTime? _lastBack;

  Future<void> _onBack(bool didPop, Object? result) async {
    if (didPop) return;
    final now = DateTime.now();
    if (_lastBack == null ||
        now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('اضغط رجوع مرة أخرى للمغادرة'),
            duration: Duration(seconds: 2)));
      return;
    }
    _lastBack = null;
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('مغادرة التطبيق'),
        content: const Text('هل تريد المغادرة أم البقاء في التطبيق؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('البقاء')),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('مغادرة')),
        ],
      ),
    );
    if (leave == true) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(tabProvider);
    const pages = [
      DashboardPage(),
      ProductsScreen(),
      PosScreen(),
      MoreScreen(),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        body: SafeArea(child: pages[tab]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) =>
              ref.read(tabProvider.notifier).state = i,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'الرئيسية'),
            NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'المنتجات'),
            NavigationDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: 'بيع'),
            NavigationDestination(
                icon: Icon(Icons.more_horiz), label: 'المزيد'),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(bootProvider).valueOrNull?.session;
    final t = ref.watch(todayProvider).valueOrNull;
    final s = ref.watch(statsProvider).valueOrNull;

    void open(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ShopHeader(
          session: session,
          onSound: () async {
            await SoundService.setEnabled(!SoundService.enabled);
            setState(() {});
          },
        ),
        if (session != null && !session.isActive)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(kExpiredMsg,
                style: TextStyle(color: AppColors.danger)),
          ),
        const SizedBox(height: 16),
        Row(children: [
          _ActionTile(
            icon: Icons.point_of_sale_rounded,
            label: 'بيع جديد',
            onTap: () => ref.read(tabProvider.notifier).state = 2,
          ),
          if (canPurchase(session)) ...[
            const SizedBox(width: 10),
            _ActionTile(
              icon: Icons.inventory_rounded,
              label: 'إضافة بضاعة',
              onTap: () => open(const PurchaseScreen()),
            ),
          ],
          const SizedBox(width: 10),
          _ActionTile(
            icon: Icons.add_box_rounded,
            label: 'منتج جديد',
            onTap: () => open(const ProductForm()),
          ),
        ]),
        const SizedBox(height: 16),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => open(const InvoicesScreen()),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('مبيعات اليوم',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text(t == null ? '—' : iqd(t.salesTotal),
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.emerald)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _SmallStat(
            title: 'فواتير اليوم',
            value: t == null ? '—' : '${t.invoiceCount}',
            onTap: () => open(const InvoicesScreen()),
          ),
          const SizedBox(width: 10),
          _SmallStat(
            title: 'المنتجات',
            value: s == null ? '—' : '${s.productCount}',
            onTap: () {
              ref.read(lowOnlyProvider.notifier).state = false;
              ref.read(tabProvider.notifier).state = 1;
            },
          ),
          const SizedBox(width: 10),
          _SmallStat(
            title: 'النقوصات',
            value: s == null ? '—' : '${s.shortages}',
            color: (s?.shortages ?? 0) > 0
                ? AppColors.danger
                : AppColors.emerald,
            onTap: () {
              ref.read(lowOnlyProvider.notifier).state = true;
              ref.read(tabProvider.notifier).state = 1;
            },
          ),
        ]),
      ],
    );
  }
}

class _ShopHeader extends StatelessWidget {
  final Session? session;
  final VoidCallback onSound;
  const _ShopHeader({required this.session, required this.onSound});

  @override
  Widget build(BuildContext context) {
    final s = session;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emerald, Color(0xFF0F4D41)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: AppColors.emerald),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'الأصوات',
              onPressed: onSound,
              icon: Icon(
                SoundService.enabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: Colors.white,
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Text(
            s?.storeName ?? 'محلي',
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white),
          ),
          const SizedBox(height: 6),
          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          if (s != null)
            Text('مرحباً ${s.userName}  •  ${s.roleLabel}',
                style: const TextStyle(color: Colors.white70)),
          if (s != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                s.isActive ? 'متبقي ${s.daysLeft} يوم' : 'الاشتراك منتهي',
                style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              CircleAvatar(
                backgroundColor: AppColors.mint,
                child: Icon(icon, color: AppColors.emerald),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;
  const _SmallStat({
    required this.title,
    required this.value,
    required this.onTap,
    this.color = AppColors.emerald,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}
