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

    void msg(String m) => ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));

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
          final activeCount =
              docs.where((d) => d.data()['active'] == true).length;
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
                                    await svc.setMemberActive(
                                        s.storeId, d.id, v);
                                  } catch (e) {
                                    if (context.mounted) {
                                      msg(authMessage(e));
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
                      msg(kExpiredMsg);
                      return;
                    }
                    if (activeCount >= s.maxUsers) {
                      msg('وصلت للحد الأقصى من المستخدمين في باقتك');
                      return;
                    }
                    try {
                      final code = await svc.createStaffInvite(s, 'cashier');
                      if (context.mounted) await showCodeDialog(context, code);
                    } catch (e) {
                      if (context.mounted) msg(authMessage(e));
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
