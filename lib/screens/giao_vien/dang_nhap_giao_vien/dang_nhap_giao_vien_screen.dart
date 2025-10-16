import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quan_ly_hoc_sinh/models/hoc_sinh.dart';
import 'package:quan_ly_hoc_sinh/screens/component_widget/google_login_button.dart';
import 'package:quan_ly_hoc_sinh/screens/hoc_sinh/main/main_hoc_sinh.dart';
import 'package:quan_ly_hoc_sinh/screens/main_screen.dart';
import 'package:quan_ly_hoc_sinh/services/local_data_service.dart';
import 'package:quan_ly_hoc_sinh/models/user.dart';

import '../../../services/hoc_sinh_service.dart';
import '../../../services/user_service.dart';

class DangNhapGiaoVienScreen extends StatefulWidget {
  const DangNhapGiaoVienScreen({super.key});

  @override
  State<DangNhapGiaoVienScreen> createState() => _DangNhapGiaoVienScreenState();
}

class _DangNhapGiaoVienScreenState extends State<DangNhapGiaoVienScreen> {
  bool _isLoading = false;
  bool _isInitializing = true;
  LocalDataService localDataService = LocalDataService.instance;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang khởi tạo ứng dụng...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'HỆ THỐNG QUẢN LÝ HỌC SINH',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  GoogleLoginButton(
                    onLoginSuccess: _checkAuth,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkAuth() async {

  }
}
