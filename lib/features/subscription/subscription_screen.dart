import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/firebase_config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../auth/auth_providers.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bootProvider).valueOrNull?.session;
    if (s == null) {
      return const Scaffold(body: Center(child: Text('لا توجد بيانات اشتراك')));
    }
    final active = s.isActive;
    final color = !active
        ? AppColors.danger
        : (s.daysLeft <= 5 ? AppColors.gold : AppColors.emerald);

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text(k, style: const TextStyle(color: Colors.grey))),
              Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('اشتراكي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Chip(
                    label: Text(active ? 'اشتراك فعال' : 'منتهي'),
                    backgroundColor: color.withOpacity(0.12),
                    labelStyle: TextStyle(color: color),
                  ),
                  const SizedBox(height: 8),
                  Text('${s.daysLeft}',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  const Text('يوم متبقٍ'),
                  const Divider(height: 28),
                  row('الباقة', s.plan.isEmpty ? '—' : s.plan),
                  row('تاريخ التفعيل', fmtDate(s.start)),
                  row('تاريخ الانتهاء', fmtDate(s.end)),
                  row('عدد المستخدمين المسموح', '${s.maxUsers}'),
                ],
              ),
            ),
          ),
          if (!active)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(kExpiredMsg, style: TextStyle(color: AppColors.danger)),
            ),
          const SizedBox(height: 12),
          if (FirebaseConfig.supportWhatsapp.isNotEmpty)
            FilledButton.icon(
              icon: const Icon(Icons.chat_outlined),
              label: const Text('تجديد / التواصل مع الإدارة'),
              onPressed: () {
                final msg = Uri.encodeComponent(
                    'أرغب بتجديد اشتراك محلي - المحل: ${s.storeName}');
                launchUrl(
                  Uri.parse(
                      'https://wa.me/${FirebaseConfig.supportWhatsapp}?text=$msg'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('تحديث حالة الاشتراك'),
            onPressed: () => ref.invalidate(bootProvider),
          ),
        ],
      ),
    );
  }
}
