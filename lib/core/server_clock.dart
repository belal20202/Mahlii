import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ساعة معتمدة على وقت الخادم. لا تعتمد على ساعة الهاتف وحدها.
/// العرض في التطبيق تقديري، والفرض الحقيقي يتم في Firestore Rules.
class ServerClock {
  static int _offsetMs = 0;
  static int _lastKnownMs = 0;
  static int _lastPersist = 0;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _offsetMs = p.getInt('clock_offset') ?? 0;
    _lastKnownMs = p.getInt('clock_last') ?? 0;
  }

  static DateTime now() {
    final est = DateTime.now().millisecondsSinceEpoch + _offsetMs;
    // منع الرجوع بالزمن لأن آخر وقت معروف يبقى هو الحد الأدنى
    if (est > _lastKnownMs) _lastKnownMs = est;
    _persistSoon();
    return DateTime.fromMillisecondsSinceEpoch(_lastKnownMs);
  }

  static Future<void> _persistSoon() async {
    final t = DateTime.now().millisecondsSinceEpoch;
    if (t - _lastPersist < 60000) return;
    _lastPersist = t;
    final p = await SharedPreferences.getInstance();
    await p.setInt('clock_offset', _offsetMs);
    await p.setInt('clock_last', _lastKnownMs);
  }

  static Future<void> sync() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await ref
          .update({'lastSeen': FieldValue.serverTimestamp()})
          .timeout(const Duration(seconds: 6));
      final snap = await ref
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 6));
      final ts = (snap.data()?['lastSeen'] as Timestamp?)?.toDate();
      if (ts != null) {
        _offsetMs =
            ts.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
        _lastKnownMs = ts.millisecondsSinceEpoch;
        _lastPersist = 0;
        await _persistSoon();
      }
    } catch (_) {
      // بدون إنترنت: نستخدم آخر فرق محفوظ
    }
  }
}
