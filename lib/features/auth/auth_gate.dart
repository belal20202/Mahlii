import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/admin_screen.dart';
import '../home/home_shell.dart';
import 'auth_providers.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authUserProvider);
    return auth.when(
      loading: () => const _Loading('جارٍ التحميل...'),
      error: (_, __) => const LoginScreen(),
      data: (user) {
        if (user == null) return const LoginScreen();
        final boot = ref.watch(bootProvider);
        return boot.when(
          loading: () => const _Loading('جارٍ تجهيز الحساب...'),
          error: (e, _) => _Problem(
            message: authMessage(e),
            canRetry: e is! AccountDisabledException,
          ),
          data: (b) {
            if (b.session != null) return const HomeShell();
            if (b.isAdmin) return const AdminScreen();
            return const _Problem(
              message: 'هذا الحساب غير مرتبط بأي محل بعد',
              canRetry: true,
            );
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  final String text;
  const _Loading(this.text);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(text),
            ],
          ),
        ),
      );
}

class _Problem extends ConsumerWidget {
  final String message;
  final bool canRetry;
  const _Problem({required this.message, required this.canRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 48),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                if (canRetry)
                  FilledButton(
                    onPressed: () => ref.invalidate(bootProvider),
                    child: const Text('إعادة المحاولة'),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.read(authServiceProvider).logout(),
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        ),
      );
}

class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'إعدادات Firebase غير مضافة لهذا البناء.\n'
              'أضف أسرار FB_* في GitHub ثم أعد البناء (راجع README).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}
