import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_hoc_sinh/screens/giao_vien/quan_ly_lop_chu_nhiem/quan_ly_ra_vao_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/giao_vien/truc_ban/truc_ban_screen.dart';
import 'package:quan_ly_hoc_sinh/services/local_data_service.dart';
import '../../../models/giao_vien.dart';
import '../../../services/giao_vien_service.dart';

class MainGiaoVienScreen extends StatefulWidget {
  const MainGiaoVienScreen({Key? key}) : super(key: key);

  @override
  State<MainGiaoVienScreen> createState() => _MainGiaoVienScreenState();
}

class _MainGiaoVienScreenState extends State<MainGiaoVienScreen> {
  GiaoVien? _giaoVien;
  bool _isLoading = true;
  LocalDataService _localDataService = LocalDataService.instance;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      String? id = _localDataService.getId();
      if (id != null) {
        final giaoVien = await GiaoVienService.getGiaoVienById(id);
        setState(() {
          _giaoVien = giaoVien;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_giaoVien == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thông tin giáo viên')),
        body: const Center(
          child: Text('Không tìm thấy thông tin giáo viên'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chính giáo viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeacherInfoCard(),
            const SizedBox(height: 24),
            _buildFeatureButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: _giaoVien?.avatarUrl != null
                  ? NetworkImage(_giaoVien!.avatarUrl!)
                  : null,
              child: _giaoVien?.avatarUrl == null
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              _giaoVien!.hoTen,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _giaoVien!.chucVu ?? 'Giáo viên',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone, 'Số điện thoại', _giaoVien!.soDienThoai),
            _buildInfoRow(
              Icons.email,
              'Email',
              _giaoVien!.email ?? 'Chưa cập nhật'
            ),
            _buildInfoRow(
              Icons.badge,
              'CMND/CCCD',
              _giaoVien!.cmndCccd ?? 'Chưa cập nhật'
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Ngày sinh',
              _giaoVien!.ngaySinh != null
                  ? '${_giaoVien!.ngaySinh!.day}/${_giaoVien!.ngaySinh!.month}/${_giaoVien!.ngaySinh!.year}'
                  : 'Chưa cập nhật',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tính năng',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureButton(
            title: 'Thống kê học sinh ra vào theo lớp',
            icon: Icons.bar_chart,
            color: Colors.orange,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => QuanLyLopChuNhiemScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildFeatureButton(
            title: 'Thống kê phụ huynh đến thăm',
            icon: Icons.people,
            color: Colors.purple,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => QuanLyLopChuNhiemScreen(isQuanLyRaVao: false)));
            },
          ),
          const SizedBox(height: 12),
          _buildFeatureButton(
            title: 'Thông tin trực ban',
            icon: Icons.people,
            color: Colors.purple,
            onPressed: () {
              if (_giaoVien == null) return;
              Navigator.push(context, MaterialPageRoute(builder: (context) => TrucBanScreen(
                idGiaoVien: _giaoVien!.id!,
                tenGiaoVien: _giaoVien!.hoTen,
              )));
            },
          ),
          SizedBox(height: 20)
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}