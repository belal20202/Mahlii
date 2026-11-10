import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'auth_providers.dart';
import 'auth_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _key = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _userName = TextEditingController();
  final _ownerName = TextEditingController();
  final _storeName = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _owner = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_code, _userName, _ownerName, _storeName, _phone, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null;

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).register(
            owner: _owner,
            code: _code.text,
            userName: _userName.text.trim(),
            phone: _phone.text.trim(),
            password: _pass.text,
            ownerName: _ownerName.text.trim(),
            storeName: _storeName.text.trim(),
          );
      ref.invalidate(bootProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = authMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _f(String label, TextEditingController c,
      {bool required = true,
      bool obscure = false,
      TextInputType? type,
      bool ltr = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: type,
        textDirection: ltr ? TextDirection.ltr : null,
        validator: required
            ? (v) {
                final r = _req(v);
                if (r != null) return r;
                if (obscure && v!.length < 6) return '6 أحرف على الأقل';
                return null;
              }
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفعيل حساب')),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('مالك محل')),
                ButtonSegment(value: false, label: Text('موظف')),
              ],
              selected: {_owner},
              onSelectionChanged: (s) => setState(() => _owner = s.first),
            ),
            const SizedBox(height: 16),
            _f('رمز التسجيل', _code, ltr: true),
            _f('اسم المستخدم', _userName),
            if (_owner) ...[
              _f('اسم صاحب المحل', _ownerName),
              _f('اسم المحل', _storeName),
            ],
            _f('رقم الهاتف', _phone, type: TextInputType.phone, ltr: true),
            _f('كلمة المرور', _pass, obscure: true),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.danger)),
              ),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'جارٍ التفعيل...' : 'تفعيل الحساب'),
            ),
            const SizedBox(height: 10),
            const Text(
              'يتطلب التفعيل اتصالاً بالإنترنت. استخدم رقم الهاتف نفسه عند الدخول لاحقاً.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
