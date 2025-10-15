import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

import 'package:quan_ly_hoc_sinh/screens/test_screen.dart';

class SimpleAuthScreen extends StatefulWidget {
  const SimpleAuthScreen({super.key});

  @override
  State<SimpleAuthScreen> createState() => _SimpleAuthScreenState();
}

class _SimpleAuthScreenState extends State<SimpleAuthScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    // setState(() {
    //   _isLoading = true;
    // });
    //
    // try {
    //   final GoogleSignIn googleSignIn = GoogleSignIn();
    //   final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    //
    //   if (googleUser == null) {
    //     throw Exception('Google sign in was cancelled');
    //   }
    //
    //   final GoogleSignInAuthentication googleAuth =
    //       await googleUser.authentication;
    //   final credential = GoogleAuthProvider.credential(
    //     accessToken: googleAuth.accessToken,
    //     idToken: googleAuth.idToken,
    //   );
    //
    //   final UserCredential userCredential = await FirebaseAuth.instance
    //       .signInWithCredential(credential);
    //
    //   if (userCredential.user != null) {
    //     if (mounted) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(
    //           content: Text('Đăng nhập thành công!'),
    //           backgroundColor: Colors.green,
    //         ),
    //       );
    //     }
    //   }
    // } catch (e) {
    //
    //   if (mounted) {
    //
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text('Lỗi đăng nhập: ${e.toString()}'),
    //         backgroundColor: Colors.red,
    //       ),
    //     );
    //   }
    // } finally {
    //   if (mounted) {
    //     setState(() {
    //       _isLoading = false;
    //     });
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Google Sign-in'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Test Google Sign-in',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Đăng nhập với Google'),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => TestScreen()),
                );
              },
              child: const Text('Chuyển đến Test Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
