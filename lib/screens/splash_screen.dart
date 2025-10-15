import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import 'auth_screen.dart';
import 'giao_vien_screen.dart';
import 'hoc_sinh_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkUserAndNavigate();
  }



  Future<void> checkUserAndNavigate() async {
    // Add delay to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Get stored user data
    UserModel? user = await UserService.getCurrentUser();

    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
    } else {
      switch (user.role) {
        case UserRole.hocsinh:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HocSinhScreen()));
          break;
        case UserRole.giaovien:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GiaoVienScreen()));
          break;
        default:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen(user: user)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 120,color: Colors.blue),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
