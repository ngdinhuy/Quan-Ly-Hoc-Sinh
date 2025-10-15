import 'package:flutter/material.dart';
import '../../../models/hoc_sinh.dart';
import '../../../services/hoc_sinh_service.dart';
import '../../../services/local_data_service.dart';
import '../main/main_hoc_sinh.dart';

class DangNhapHocSinhScreen extends StatefulWidget {
  const DangNhapHocSinhScreen({super.key});

  @override
  State<DangNhapHocSinhScreen> createState() => _DangNhapHocSinhScreenState();
}

class _DangNhapHocSinhScreenState extends State<DangNhapHocSinhScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Vui lòng nhập đầy đủ thông tin';
      });
      return;
    }

    try {
      HocSinh? hocSinh = await HocSinhService.login(username, password);

      if ( hocSinh!= null && hocSinh.id != null) {
        // Save student ID to local storage
        final idHocSinh = hocSinh.id;
        await LocalDataService.instance.saveIdHocSinh(idHocSinh!);

        if (!mounted) return;

        // Navigate to the main student screen and remove all previous routes
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MainHocSinhScreen(hocSinh: hocSinh))
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Đăng nhập thất bại';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Đăng Nhập',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'ID học sinh',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Đăng Nhập',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
