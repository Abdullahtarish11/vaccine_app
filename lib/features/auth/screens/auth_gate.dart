import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../home/screens/home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // أثناء انتظار البيانات، أظهر شاشة تحميل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // إذا كان المستخدم مسجلاً دخوله (لديه بيانات)
        if (snapshot.hasData) {
          return const HomeScreen(); // اذهب إلى الشاشة الرئيسية
        }

        // إذا لم يكن المستخدم مسجلاً دخوله
        return const LoginScreen(); // اذهب إلى شاشة تسجيل الدخول
      },
    );
  }
}