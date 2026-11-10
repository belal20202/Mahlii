import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'auth_providers.dart';
import 'auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_phone.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'أدخل رقم الهاتف وكلمة المرور');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).login(_phone.text.trim(), _pass.text);
      ref.invalidate(bootProvider);
    } catch (e) {
      if (mounted) setState(() => _error = authMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const Icon(Icons.storefront_rounded,
                      size: 64, color: AppColors.emerald),
                  const SizedBox(height: 8),
                  const Text('محلي',
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock_outline)),
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _login,
                    child: Text(_busy ? 'جارٍ الدخول...' : 'تسجيل الدخول'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text('لدي رمز تسجيل'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
