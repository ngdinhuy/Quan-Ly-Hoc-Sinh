import 'package:flutter/material.dart';
import 'package:quan_ly_hoc_sinh/screens/cau_hinh_diem_danh_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/phan_cong_chu_nhiem_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/phan_cong_truc_ban_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/thong_ke_di_muon_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/quan_ly_diem_danh_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/thong_ke_xuat_an_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/ve_phep_admin_screen.dart';
import '../models/user.dart' as app_user;
import '../services/user_service.dart';
import 'truong_screen.dart';
import 'khoi_lop_screen.dart';
import 'giao_vien_screen.dart';
import 'hoc_sinh_screen.dart';
import 'ra_vao_screen.dart';
import 'phu_huynh_screen.dart';
import 'bao_cao_screen.dart';
import 'admin_management_screen.dart';
import 'auth_screen.dart';

class MainScreen extends StatefulWidget {
  final app_user.UserModel user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens {
    final screens = <Widget>[];
    if (_canAccess('truong')) screens.add(const TruongScreen());
    if (_canAccess('khoi_lop')) screens.add(const KhoiLopScreen());
    if (_canAccess('giao_vien')) screens.add(const GiaoVienScreen());
    if (_canAccess('hoc_sinh')) screens.add(const HocSinhScreen());
    if (_canAccess('ra_vao')) screens.add(const RaVaoScreen());
    if (_canAccess('phu_huynh')) screens.add(const PhuHuynhScreen());
    if (_canAccess('bao_cao')) screens.add(const BaoCaoScreen());
    if (_canAccess('phan_cong_chu_nhiem'))
      screens.add(const PhanCongChuNhiemScreen());
    if (_canAccess('phan_cong_truc_ban'))
      screens.add(const PhanCongTrucBanScreen());
    if (_canAccess('xin_ve_phep')) screens.add(const VePhepAdminScreen());
    if (_canAccess('thong_ke_xuat_an'))
      screens.add(const ThongKeXuatAnScreen());
    if (_canAccess('cau_hinh_diem_danh'))
      screens.add(const CauHinhDiemDanhScreen());
    if (_canAccess('thong_ke_di_muon'))
      screens.add(const ThongKeDiMuonScreen());
    if (_canAccess('quan_ly_diem_danh')) {
      screens.add(const QuanLyDiemDanhScreen());
    }
    if (_canAccess('admin')) screens.add(const AdminManagementScreen());
    return screens;
  }

  List<String> get _titles {
    final titles = <String>[];
    if (_canAccess('truong')) titles.add('Trường Học');
    if (_canAccess('khoi_lop')) titles.add('Khối & Lớp');
    if (_canAccess('giao_vien')) titles.add('Giáo Viên');
    if (_canAccess('hoc_sinh')) titles.add('Học Sinh');
    if (_canAccess('ra_vao')) titles.add('Ra Vào Trường');
    if (_canAccess('phu_huynh')) titles.add('Phụ Huynh');
    if (_canAccess('bao_cao')) titles.add('Báo Cáo');
    if (_canAccess('phan_cong_chu_nhiem')) titles.add('Phân Công Chủ Nhiệm');
    if (_canAccess('phan_cong_truc_ban')) titles.add('Phân Công Trực Ban');
    if (_canAccess('xin_ve_phep')) titles.add('Xin về phép');
    if (_canAccess('thong_ke_xuat_an')) titles.add('Thống Kê Xuất Ăn');
    if (_canAccess('cau_hinh_diem_danh')) titles.add('Cấu Hình Điểm Danh');
    if (_canAccess('thong_ke_di_muon')) titles.add('Thống Kê Điểm Danh');
    if (_canAccess('quan_ly_diem_danh')) titles.add('Quản Lý Điểm Danh');
    if (_canAccess('admin')) titles.add('Quản lý Admin');
    return titles;
  }

  bool _canAccess(String feature) {
    switch (widget.user.role) {
      case app_user.UserRole.admin:
        return true; // Admin can access everything
      case app_user.UserRole.phuhuynh:
        return false;
      case app_user.UserRole.giaovien:
        return [
          'giao_vien',
          'hoc_sinh',
          'ra_vao',
          'phu_huynh',
          'bao_cao',
          'xin_ve_phep',
        ].contains(feature);
      case app_user.UserRole.hocsinh:
        return ['ra_vao'].contains(feature);
    }
  }

  Future<void> _signOut() async {
    await UserService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  String _getRoleDisplayName(app_user.UserRole role) {
    switch (role) {
      case app_user.UserRole.admin:
        return 'Quản trị viên';
      case app_user.UserRole.giaovien:
        return 'Giáo viên';
      case app_user.UserRole.hocsinh:
        return 'Học sinh';
      case app_user.UserRole.phuhuynh:
        return 'Phụ huynh';
    }
  }

  List<Widget> _buildMenuItems() {
    final menuItems = <Widget>[];
    int index = 0;

    if (_canAccess('truong')) {
      menuItems.add(_buildMenuItem(index++, Icons.school, 'Trường Học'));
    }
    if (_canAccess('khoi_lop')) {
      menuItems.add(_buildMenuItem(index++, Icons.class_, 'Khối & Lớp'));
    }
    if (_canAccess('giao_vien')) {
      menuItems.add(_buildMenuItem(index++, Icons.person, 'Giáo Viên'));
    }
    if (_canAccess('hoc_sinh')) {
      menuItems.add(_buildMenuItem(index++, Icons.child_care, 'Học Sinh'));
    }
    if (_canAccess('ra_vao')) {
      menuItems.add(_buildMenuItem(index++, Icons.login, 'Ra Vào Trường'));
    }
    if (_canAccess('phu_huynh')) {
      menuItems.add(
        _buildMenuItem(index++, Icons.family_restroom, 'Phụ Huynh'),
      );
    }
    if (_canAccess('bao_cao')) {
      menuItems.add(_buildMenuItem(index++, Icons.analytics, 'Báo Cáo'));
    }
    if (_canAccess('phan_cong_chu_nhiem')) {
      menuItems.add(
        _buildMenuItem(index++, Icons.assignment, 'Phân Công Chủ Nhiệm'),
      );
    }
    if (_canAccess('phan_cong_truc_ban')) {
      menuItems.add(
        _buildMenuItem(index++, Icons.schedule, 'Phân Công Trực Ban'),
      );
    }
    if (_canAccess('xin_ve_phep')) {
      menuItems.add(
        _buildMenuItem(index++, Icons.event_available, 'Xin về phép'),
      );
    }
    if (_canAccess('thong_ke_xuat_an')) {
      menuItems.add(
        _buildMenuItem(index++, Icons.restaurant_menu, 'Thống Kê Xuất Ăn'),
      );
    }
    if (_canAccess('cau_hinh_diem_danh')) {
      menuItems.add(
        _buildMenuItem(index++, Icons.schedule, 'Cấu Hình Điểm Danh'),
      );
    }
    if (_canAccess('thong_ke_di_muon')) {
      menuItems.add(
        _buildMenuItem(index++, Icons.warning_amber, 'Thống Kê Điểm Danh'),
      );
    }
    if (_canAccess('quan_ly_diem_danh')) {
      menuItems.add(
        _buildMenuItem(index++, Icons.fact_check, 'Quản Lý Điểm Danh'),
      );
    }
    if (_canAccess('admin')) {
      menuItems.add(
        _buildMenuItem(index++, Icons.admin_panel_settings, 'Quản lý Admin'),
      );
    }

    return menuItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundImage: widget.user.photoUrl != null
                        ? NetworkImage(widget.user.photoUrl!)
                        : null,
                    child: widget.user.photoUrl == null
                        ? Text(
                            widget.user.displayName.isNotEmpty
                                ? widget.user.displayName[0].toUpperCase()
                                : 'U',
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.user.displayName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        _getRoleDisplayName(widget.user.role),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.indigo.shade800,
                  Colors.indigo.shade900,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header với logo/title
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo.shade600,
                        Colors.indigo.shade800,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.school,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Colors.amber,
                            Colors.orangeAccent,
                            Colors.yellow,
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'QUẢN LÝ HỌC SINH',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade400,
                              Colors.cyan.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'RA VÀO KÝ TÚC XÁ',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Trường Dân Tộc Nội Trú',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.lightBlue.shade200,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Menu items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: _buildMenuItems(),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '© 2024 QLHS System',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.blue.shade600,
                ],
              )
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          hoverColor: Colors.white.withValues(alpha: 0.1),
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
