import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
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

  void _msg(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

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
                    decoration: const InputDecoration(labelText: 'عدد الأيام'))),
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
              return Column(
                children: [
                  for (final d in snap.data!.docs) _storeCard(svc, d),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _storeCard(AuthService svc, QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final start = (m['subscriptionStart'] as Timestamp?)?.toDate();
    final days = (m['planDays'] as num).toInt();
    final end = start?.add(Duration(days: days));
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('المالك: ${m['ownerName']}'),
            Text('ينتهي: ${end == null ? '—' : fmtDate(end)}   •   مستخدمون: ${m['maxUsers']}'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              OutlinedButton(
                onPressed: () async {
                  try {
                    await svc.extendDays(d.id, 30);
                  } catch (e) {
                    _msg(authMessage(e));
                  }
                },
                child: const Text('تمديد 30 يوماً'),
              ),
              OutlinedButton(
                onPressed: () async {
                  try {
                    await svc.renewFromNow(d.id, 30);
                  } catch (e) {
                    _msg(authMessage(e));
                  }
                },
                child: const Text('تجديد من اليوم'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
