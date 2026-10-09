import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // الرمز السري لإنشاء حساب مدير النظام - يمكن تغييره من هنا
  static const String adminSecretCode = 'ADMIN2024';

  // Sign up + save to Firestore (document id == uid)
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? centerName,
    String? centerLocation,
    String? adminCode, // الرمز السري للمدير
  }) async {
    final normalizedRole = role.trim();

    // التحقق من الرمز السري إذا كان الدور Admin
    if (normalizedRole == 'admin') {
      if (adminCode == null || adminCode.trim() != adminSecretCode) {
        throw Exception('الرمز السري لإنشاء حساب المدير غير صحيح. يرجى التواصل مع الدعم الفني.');
      }
    }

    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user!;
    final docRef = _firestore.collection('users').doc(user.uid);

    final data = {
      'uid': user.uid,
      'email': email.trim(),
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'role': normalizedRole,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await docRef.set(data);
      if (normalizedRole == 'counter' || normalizedRole == 'center') {
        await _firestore.collection('centers').add({
          'centerName': (centerName ?? fullName).trim(),
          'location': (centerLocation ?? '').trim(),
          'phone': phone.trim(),
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      // rollback auth user if Firestore write fails
      await user.delete();
      rethrow;
    }
  }

  // Sign in and return Firestore user data
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;
    final snap = await _firestore.collection('users').doc(uid).get();

    if (!snap.exists) throw Exception('User document not found in Firestore.');
    return snap.data()!;
  }

  Future<Map<String, dynamic>?> fetchUserByUid(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    return snap.exists ? snap.data() : null;
  }

  /// Search for users by email or full name. Returns a list of user data maps.
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return [];

    final snap = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    final matches = snap.docs.map((doc) => doc.data()).where((user) {
      final email = (user['email'] ?? '').toString().trim().toLowerCase();
      final name = (user['fullName'] ?? '').toString().trim().toLowerCase();
      final phone = (user['phone'] ?? '').toString().trim().toLowerCase();
      return email.contains(normalizedQuery) ||
          name.contains(normalizedQuery) ||
          phone.contains(normalizedQuery);
    }).toList();

    return matches;
  }

  Future<void> signOut() => _auth.signOut();
}
