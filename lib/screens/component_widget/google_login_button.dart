import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quan_ly_hoc_sinh/models/user.dart';
import 'package:quan_ly_hoc_sinh/services/user_service.dart';

class GoogleLoginButton extends StatefulWidget {
  final Function()? onLoginSuccess;

  const GoogleLoginButton({
    super.key,
    this.onLoginSuccess,
  });

  @override
  State<GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<GoogleLoginButton> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      UserModel userModel = await UserService.signInWithGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Call the onLoginSuccess callback if provided
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi đăng nhập: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const CircularProgressIndicator()
        : ElevatedButton.icon(
            onPressed: _signIn,
            icon: const Icon(Icons.login),
            label: const Text('Đăng nhập với Google'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          );
  }
}
