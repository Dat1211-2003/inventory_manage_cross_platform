import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventory_manage/screens/home_screen.dart';
import 'package:inventory_manage/screens/login_screen.dart';

/// Widget lắng nghe Firebase Auth stream và điều hướng tự động.
/// Đặt làm root widget thay cho HomeScreen trực tiếp.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Đang chờ kết nối Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Đã đăng nhập → vào app
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // Chưa đăng nhập → màn hình login
        return const LoginScreen();
      },
    );
  }
}
