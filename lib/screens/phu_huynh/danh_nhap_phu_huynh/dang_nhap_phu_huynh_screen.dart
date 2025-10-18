import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quan_ly_hoc_sinh/models/giao_vien.dart';
import 'package:quan_ly_hoc_sinh/models/hoc_sinh.dart';
import 'package:quan_ly_hoc_sinh/models/phu_huynh.dart';
import 'package:quan_ly_hoc_sinh/screens/component_widget/google_login_button.dart';
import 'package:quan_ly_hoc_sinh/screens/giao_vien/main_giao_vien/main_giao_vien_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/hoc_sinh/main/main_hoc_sinh.dart';
import 'package:quan_ly_hoc_sinh/screens/main_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/phu_huynh/main_phu_huynh/main_phu_huynh_screen.dart';
import 'package:quan_ly_hoc_sinh/services/giao_vien_service.dart';
import 'package:quan_ly_hoc_sinh/services/local_data_service.dart';
import 'package:quan_ly_hoc_sinh/models/user.dart';
import 'package:quan_ly_hoc_sinh/services/phu_huynh_service.dart';

import '../../../services/hoc_sinh_service.dart';
import '../../../services/user_service.dart';

class DangNhapPhuHuynhScreen extends StatefulWidget {
  const DangNhapPhuHuynhScreen({super.key});

  @override
  State<DangNhapPhuHuynhScreen> createState() => _DangNhapPhuHuynhScreenState();
}

class _DangNhapPhuHuynhScreenState extends State<DangNhapPhuHuynhScreen> {
  bool _isLoading = false;
  bool _isInitializing = false;
  LocalDataService _localDataService = LocalDataService.instance;

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
    if (_localDataService.getId() != null  && _localDataService.getRole() == UserRole.phuhuynh) {
      PhuHuynh? phuHuynh = await PhuHuynhService.getPhuHuynhById(_localDataService.getId()!);
      debugPrint("Auto login hoc sinh: $phuHuynh");
      if (phuHuynh != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainPhuHuynhScreen()),
        );
      }
    }
  }
}
