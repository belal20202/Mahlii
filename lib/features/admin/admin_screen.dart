import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_service.dart';
import '../auth/code_dialog.dart';

/// لوحة المالك العام. تظهر فقط للحسابات الموجودة في مجموعة admins،
/// والفرض الحقيقي يتم في firestore.rules.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _plan = TextEditingController(text: 'شهري');
  final _days = TextEditingController(text: '30');
  final _users = TextEditingController(text: '3');

  @override
  void dispose() {
    _plan.dispose();
    _days.dispose();
    _users.dispose();
    super.dispose();
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _create() async {
    final days = int.tryParse(_days.text.trim());
    final users = int.tryParse(_users.text.trim());
    if (days == null || days < 1 || users == null || users < 1) {
      _msg('أدخل أرقاماً صحيحة');
      return;
    }
    try {
      final code = await ref.read(authServiceProvider).createOwnerInvite(
          plan: _plan.text.trim(), days: days, maxUsers: users);
      if (mounted) await showCodeDialog(context, code);
    } catch (e) {
      _msg(authMessage(e));
    }
  }

  /// نافذة تطلب أياماً (وعدد مستخدمين اختيارياً). تعيد null عند الإلغاء.
  Future<({int days, int users})?> _ask({
    required String title,
    required int defaultDays,
    int? defaultUsers,
  }) async {
    final d = TextEditingController(text: '$defaultDays');
    final u = TextEditingController(text: '${defaultUsers ?? ''}');
    final res = await showDialog<({int days, int users})?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: d,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد الأيام'),
            ),
            if (defaultUsers != null) ...[
              const SizedBox(height: 10),
              TextField(
                controller: u,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'عدد المستخدمين'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              final days = int.tryParse(d.text.trim());
              final users =
                  defaultUsers == null ? 0 : int.tryParse(u.text.trim());
              if (days == null ||
                  days < 1 ||
                  users == null ||
                  (defaultUsers != null && users < 1)) {
                return;
              }
              Navigator.pop(ctx, (days: days, users: users));
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    d.dispose();
    u.dispose();
    return res;
  }

  Future<void> _activate(
      AuthService svc, String id, Map<String, dynamic> m) async {
    final r = await _ask(
      title: 'تفعيل / تجديد من اليوم',
      defaultDays: 30,
      defaultUsers: (m['maxUsers'] as num).toInt(),
    );
    if (r == null) return;
    try {
      await svc.activateFromNow(id, r.days, r.users);
      _msg('تم تفعيل الاشتراك');
    } catch (e) {
      _msg(authMessage(e));
    }
  }

  Future<void> _extend(AuthService svc, String id) async {
    final r = await _ask(title: 'تمديد الاشتراك', defaultDays: 30);
    if (r == null) return;
    try {
      await svc.extendDays(id, r.days);
      _msg('تم التمديد');
    } catch (e) {
      _msg(authMessage(e));
    }
  }

  Future<void> _cancel(AuthService svc, String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الاشتراك'),
        content: Text(
            'سيتوقف البيع والشراء والتعديل في "$name" فوراً، ويبقى العرض والتصدير فقط. لا تُحذف أي بيانات، ويمكنك إعادة التفعيل لاحقاً.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('تراجع')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إلغاء الاشتراك',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await svc.cancelSubscription(id);
      _msg('تم إلغاء الاشتراك');
    } catch (e) {
      _msg(authMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.read(authServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة محلي'),
        actions: [
          IconButton(
              onPressed: () => svc.logout(), icon: const Icon(Icons.logout))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('دعوة مالك محل جديد',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          TextField(
              controller: _plan,
              decoration: const InputDecoration(labelText: 'اسم الباقة')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _days,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'عدد الأيام'))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _users,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'عدد المستخدمين'))),
          ]),
          const SizedBox(height: 10),
          FilledButton(onPressed: _create, child: const Text('إنشاء الرمز')),
          const Divider(height: 36),
          const Text('المحلات',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          StreamBuilder(
            stream: svc.allStores(),
            builder: (context, snap) {
              if (snap.hasError) return const Text('تعذر تحميل المحلات');
              if (!snap.hasData) {
                return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()));
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('لا توجد محلات بعد'));
              }
              return Column(
                children: [for (final d in docs) _storeCard(svc, d)],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _storeCard(
      AuthService svc, QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final start = (m['subscriptionStart'] as Timestamp?)?.toDate();
    final days = (m['planDays'] as num).toInt();
    final end = start?.add(Duration(days: days));
    final now = DateTime.now();
    final cancelled = days == 0;

    final rawLeft = end == null ? 0 : (end.difference(now).inHours / 24).ceil();
    final left = rawLeft < 0 ? 0 : rawLeft;
    final active = !cancelled && left > 0;

    final String status =
        cancelled ? 'ملغى' : (active ? 'نشط • متبقي $left يوم' : 'منتهي');
    final color = active
        ? (left <= 5 ? AppColors.gold : AppColors.emerald)
        : AppColors.danger;
    final name = m['name'] as String;
    final endText = (cancelled || end == null) ? '—' : fmtDate(end);

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              Chip(
                label: Text(status),
                backgroundColor: color.withValues(alpha: 0.12),
                labelStyle: TextStyle(color: color, fontSize: 12),
              ),
            ]),
            Text('المالك: ${m['ownerName']}'),
            Text('ينتهي: $endText   •   مستخدمون: ${m['maxUsers']}'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14)),
                onPressed: () => _activate(svc, d.id, m),
                child: Text(active ? 'تجديد من اليوم' : 'تفعيل الاشتراك'),
              ),
              if (active)
                OutlinedButton(
                  onPressed: () => _extend(svc, d.id),
                  child: const Text('تمديد'),
                ),
              if (active)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger),
                  onPressed: () => _cancel(svc, d.id, name),
                  child: const Text('إلغاء الاشتراك'),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}
