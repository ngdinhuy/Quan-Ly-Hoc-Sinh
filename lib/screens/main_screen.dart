import 'package:flutter/material.dart';
import 'package:quan_ly_hoc_sinh/screens/phan_cong_chu_nhiem_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/phan_cong_truc_ban_screen.dart';
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
    if (_canAccess('phan_cong_chu_nhiem')) screens.add(const PhanCongChuNhiemScreen());
    if (_canAccess('phan_cong_truc_ban')) screens.add(const PhanCongTrucBanScreen());
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
            itemBuilder:
                (BuildContext context) => [
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
                    backgroundImage:
                        widget.user.photoUrl != null
                            ? NetworkImage(widget.user.photoUrl!)
                            : null,
                    child:
                        widget.user.photoUrl == null
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
            width: 250,
            color: Colors.grey[100],
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'HỆ THỐNG QUẢN LÝ HỌC SINH',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(),
                Expanded(child: ListView(children: _buildMenuItems())),
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
