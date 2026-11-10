import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_service.dart';
import '../auth/code_dialog.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bootProvider).valueOrNull?.session;
    if (s == null || !s.canManageStaff) {
      return const Scaffold(body: Center(child: Text('غير مصرح')));
    }
    final svc = ref.read(authServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الموظفون')),
      body: StreamBuilder(
        stream: svc.members(s.storeId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('تعذر تحميل الموظفين'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          final activeCount = docs.where((d) => d.data()['active'] == true).length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('المستخدمون: $activeCount من ${s.maxUsers}'),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final d in docs)
                      ListTile(
                        title: Text(d.data()['userName'] as String),
                        subtitle: Text(
                            '${Session.roleLabels[d.data()['role']] ?? ''}  •  ${d.data()['phone']}'),
                        trailing: (s.isOwner && d.id != s.uid)
                            ? Switch(
                                value: d.data()['active'] == true,
                                onChanged: (v) async {
                                  try {
                                    await svc.setMemberActive(s.storeId, d.id, v);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(authMessage(e))));
                                    }
                                  }
                                },
                              )
                            : null,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('إنشاء رمز دعوة لموظف'),
                  onPressed: () async {
                    if (!s.canWrite) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text(kExpiredMsg)));
                      return;
                    }
                    if (activeCount >= s.maxUsers) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('وصلت للحد الأقصى من المستخدمين في باقتك')));
                      return;
                    }
                    final roles = s.isOwner
                        ? ['manager', 'cashier', 'warehouse']
                        : ['cashier', 'warehouse'];
                    final role = await showDialog<String>(
                      context: context,
                      builder: (_) => SimpleDialog(
                        title: const Text('دور الموظف'),
                        children: [
                          for (final r in roles)
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, r),
                              child: Text(Session.roleLabels[r]!),
                            ),
                        ],
                      ),
                    );
                    if (role == null) return;
                    try {
                      final code = await svc.createStaffInvite(s, role);
                      if (context.mounted) await showCodeDialog(context, code);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(authMessage(e))));
                      }
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
