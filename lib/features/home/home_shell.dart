import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sound_service.dart';
import '../../core/theme.dart';
import '../../core/units.dart';
import '../barcode/scan_screen.dart';
import '../products/products_screen.dart';
import '../providers.dart';
import '../settings/more_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(tabProvider);
    const pages = [
      DashboardPage(),
      ProductsScreen(),
      ScanScreen(),
      MoreScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => ref.read(tabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'الرئيسية'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'المنتجات'),
          NavigationDestination(
              icon: Icon(Icons.qr_code_scanner), label: 'مسح'),
          NavigationDestination(
              icon: Icon(Icons.more_horiz), label: 'المزيد'),
        ],
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
    final stats = ref.watch(statsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('محلي',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            ),
            IconButton(
              tooltip: 'الأصوات',
              icon: Icon(SoundService.enabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded),
              onPressed: () async {
                await SoundService.setEnabled(!SoundService.enabled);
                setState(() {});
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        stats.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) => const Text('تعذر تحميل البيانات'),
          data: (s) => Column(
            children: [
              _StatCard(
                icon: Icons.inventory_2_rounded,
                title: 'عدد المنتجات',
                value: '${s.productCount}',
                onTap: () {
                  ref.read(lowOnlyProvider.notifier).state = false;
                  ref.read(tabProvider.notifier).state = 1;
                },
              ),
              _StatCard(
                icon: Icons.account_balance_wallet_rounded,
                title: 'قيمة المخزون (بسعر الشراء)',
                value: iqd(s.stockValue),
                onTap: () {
                  ref.read(lowOnlyProvider.notifier).state = false;
                  ref.read(tabProvider.notifier).state = 1;
                },
              ),
              _StatCard(
                icon: Icons.warning_amber_rounded,
                title: 'النقوصات',
                value: '${s.shortages}',
                color: s.shortages > 0 ? AppColors.danger : AppColors.emerald,
                onTap: () {
                  ref.read(lowOnlyProvider.notifier).state = true;
                  ref.read(tabProvider.notifier).state = 1;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'المبيعات والأرباح والفواتير تظهر هنا بعد إضافة مرحلة نقطة البيع.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.color = AppColors.emerald,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(value,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: color)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}
