import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createCenterAccount({
    required String email,
    required String password,
    required String centerName,
    required String centerId,
    String? governorate,
    String? district,
    String? address,
    String? phone,
  }) async {
    final auth = FirebaseAuth.instance;

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('فشل إنشاء حساب المركز.');

      final uid = user.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': centerName,
        'centerName': centerName,
        'centerId': centerId,
        'governorate': governorate,
        'district': district,
        'address': address,
        'phone': phone,
        'role': 'center',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'فشل إنشاء حساب المركز.');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCenterAccount(String uid) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    try {
      // حذف بيانات Firestore أولاً
      await _firestore.collection('users').doc(uid).delete();

      // حذف حساب المصادقة إذا كان المستخدم الحالي هو نفسه
      if (user != null && user.uid == uid) {
        await user.delete();
      }
    } catch (e) {
      throw Exception('فشل حذف الحساب: $e');
    }
  }
}
