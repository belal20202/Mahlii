import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';

const kExpiredMsg =
    'انتهى الاشتراك: العمليات متوقفة، ويمكنك الاطلاع على البيانات وتصديرها فقط';

final authServiceProvider = Provider((ref) => AuthService());

final authUserProvider = StreamProvider<User?>(
    (ref) => FirebaseAuth.instance.authStateChanges());

final bootProvider = FutureProvider<Boot>((ref) async {
  final user = ref.watch(authUserProvider).valueOrNull;
  if (user == null) return const Boot();
  return ref.read(authServiceProvider).loadBoot();
});

/// هل يسمح الاشتراك الحالي بعمليات الكتابة؟
bool canWriteNow(WidgetRef ref) {
  final s = ref.read(bootProvider).valueOrNull?.session;
  return s != null && s.canWrite;
}
