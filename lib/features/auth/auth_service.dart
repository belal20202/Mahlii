import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/server_clock.dart';
import '../../models/session.dart';

class InviteException implements Exception {}

class AccountDisabledException implements Exception {}

class Boot {
  final Session? session;
  final bool isAdmin;
  const Boot({this.session, this.isAdmin = false});
}

String authMessage(Object e) {
  if (e is InviteException) return 'رمز التسجيل غير صالح أو مستخدم مسبقاً';
  if (e is AccountDisabledException) {
    return 'تم إيقاف هذا الحساب من قبل مالك المحل';
  }
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'رقم الهاتف أو كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'رقم الهاتف هذا مسجل مسبقاً';
      case 'weak-password':
        return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
      case 'invalid-email':
        return 'رقم الهاتف غير صالح';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
    }
  }
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') return 'لا تملك صلاحية تنفيذ هذه العملية';
    if (e.code == 'unavailable') return 'تحقق من اتصال الإنترنت';
  }
  return 'حدث خطأ غير متوقع';
}

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;

  static String emailFor(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$digits@mahalli.app';
  }

  static String normalizeCode(String code) =>
      code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// معرّف مستند الدعوة = SHA-256 للرمز، فلا يُخزن الرمز نفسه.
  static String codeId(String code) =>
      sha256.convert(utf8.encode(normalizeCode(code))).toString();

  static String newCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    String g() => List.generate(4, (_) => alphabet[r.nextInt(alphabet.length)]).join();
    return '${g()}-${g()}-${g()}';
  }

  Future<void> login(String phone, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: emailFor(phone), password: password);
  }

  Future<void> logout() => _auth.signOut();

  Future<void> register({
    required bool owner,
    required String code,
    required String userName,
    required String phone,
    required String password,
    String ownerName = '',
    String storeName = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: emailFor(phone), password: password);
    final user = cred.user!;
    try {
      final id = codeId(code);
      final invRef = _fs.collection('invites').doc(id);
      final inv = await invRef.get(const GetOptions(source: Source.server));
      final d = inv.data();
      if (d == null || d['used'] == true) throw InviteException();
      if ((d['role'] == 'owner') != owner) throw InviteException();

      final b = _fs.batch();
      final String sid;
      final String role;
      if (owner) {
        role = 'owner';
        final storeRef = _fs.collection('stores').doc();
        sid = storeRef.id;
        b.set(storeRef, {
          'name': storeName,
          'ownerName': ownerName,
          'ownerUid': user.uid,
          'inviteId': id,
          'plan': d['plan'],
          'planDays': d['planDays'],
          'maxUsers': d['maxUsers'],
          'subscriptionStart': FieldValue.serverTimestamp(),
        });
        b.set(storeRef.collection('members').doc(user.uid), {
          'userName': userName,
          'phone': phone,
          'role': role,
          'active': true,
          'permissions': <String, bool>{},
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        role = d['role'] as String;
        sid = d['storeId'] as String;
        b.set(
            _fs.collection('stores').doc(sid).collection('members').doc(user.uid),
            {
              'userName': userName,
              'phone': phone,
              'role': role,
              'active': true,
              'permissions': <String, bool>{},
              'inviteId': id,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
      b.set(_fs.collection('users').doc(user.uid),
          {'storeId': sid, 'role': role});
      b.update(invRef, {
        'used': true,
        'usedBy': user.uid,
        'usedAt': FieldValue.serverTimestamp(),
      });
      await b.commit();
    } catch (e) {
      try {
        await user.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<Boot> loadBoot() async {
    final user = _auth.currentUser;
    if (user == null) return const Boot();
    final u = await _fs.collection('users').doc(user.uid).get();
    if (!u.exists) {
      final a = await _fs.collection('admins').doc(user.uid).get();
      return Boot(isAdmin: a.exists);
    }
    final sid = u.data()!['storeId'] as String;
    final member = await _fs
        .collection('stores')
        .doc(sid)
        .collection('members')
        .doc(user.uid)
        .get();
    final md = member.data();
    if (md == null || md['active'] != true) throw AccountDisabledException();
    final store = await _fs.collection('stores').doc(sid).get();
    final sd = store.data()!;
    final start =
        (sd['subscriptionStart'] as Timestamp?)?.toDate() ?? ServerClock.now();
    unawaited(ServerClock.sync());
    return Boot(
      session: Session(
        uid: user.uid,
        storeId: sid,
        storeName: sd['name'] as String,
        userName: md['userName'] as String,
        role: md['role'] as String,
        plan: (sd['plan'] ?? '') as String,
        start: start,
        planDays: (sd['planDays'] as num).toInt(),
        maxUsers: (sd['maxUsers'] as num).toInt(),
      ),
    );
  }

  // ---------- الدعوات ----------
  Future<String> createOwnerInvite({
    required String plan,
    required int days,
    required int maxUsers,
  }) async {
    final code = newCode();
    await _fs.collection('invites').doc(codeId(code)).set({
      'role': 'owner',
      'plan': plan,
      'planDays': days,
      'maxUsers': maxUsers,
      'used': false,
      'createdBy': _auth.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  Future<String> createStaffInvite(Session s, String role) async {
    final code = newCode();
    await _fs.collection('invites').doc(codeId(code)).set({
      'role': role,
      'storeId': s.storeId,
      'used': false,
      'createdBy': s.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  // ---------- الموظفون ----------
  Stream<QuerySnapshot<Map<String, dynamic>>> members(String storeId) => _fs
      .collection('stores')
      .doc(storeId)
      .collection('members')
      .snapshots();

  Future<void> setMemberActive(String storeId, String uid, bool active) => _fs
      .collection('stores')
      .doc(storeId)
      .collection('members')
      .doc(uid)
      .update({'active': active});

  // ---------- لوحة الإدارة العامة ----------
  Stream<QuerySnapshot<Map<String, dynamic>>> allStores() =>
      _fs.collection('stores').snapshots();

  Future<void> extendDays(String storeId, int days) => _fs
      .collection('stores')
      .doc(storeId)
      .update({'planDays': FieldValue.increment(days)});

  Future<void> renewFromNow(String storeId, int days) =>
      _fs.collection('stores').doc(storeId).update({
        'subscriptionStart': FieldValue.serverTimestamp(),
        'planDays': days,
      });
}
