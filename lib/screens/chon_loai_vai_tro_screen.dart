import 'package:flutter/material.dart';
import 'package:quan_ly_hoc_sinh/models/giao_vien.dart';
import 'package:quan_ly_hoc_sinh/models/phu_huynh.dart';
import 'package:quan_ly_hoc_sinh/screens/giao_vien/dang_nhap_giao_vien/dang_nhap_giao_vien_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/giao_vien/main_giao_vien/main_giao_vien_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/phu_huynh/danh_nhap_phu_huynh/dang_nhap_phu_huynh_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/phu_huynh/main_phu_huynh/main_phu_huynh_screen.dart';
import 'package:quan_ly_hoc_sinh/services/giao_vien_service.dart';
import 'package:quan_ly_hoc_sinh/services/phu_huynh_service.dart';
import '../models/hoc_sinh.dart';
import '../models/user.dart';
import '../services/hoc_sinh_service.dart';
import '../services/local_data_service.dart';
import 'hoc_sinh/dang_nhap_hoc_sinh/dang_nhap_hoc_sinh_screen.dart';
import 'hoc_sinh/main/main_hoc_sinh.dart';

class ChonLoaiVaiTroScreen extends StatefulWidget {
  @override
  _ChonLoaiVaiTroScreenState createState() => _ChonLoaiVaiTroScreenState();
}

class _ChonLoaiVaiTroScreenState extends State<ChonLoaiVaiTroScreen> {
  String? selectedType;
  LocalDataService localDataService = LocalDataService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chọn Vai Trò'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUserTypeCard('Giáo Viên', Icons.school),
            SizedBox(height: 24),
            _buildUserTypeCard('Học Sinh', Icons.person),
            SizedBox(height: 24),
            _buildUserTypeCard('Phụ huynh', Icons.family_restroom),
            SizedBox(height: 40),
            if (selectedType != null)
              ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  'Tiếp tục',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(String type, IconData icon) {
    final isSelected = selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
        });
      },
      child: Card(
        color: isSelected ? Colors.blue.shade100 : Colors.white,
        elevation: isSelected ? 8 : 2,
        child: ListTile(
          leading: Icon(icon, color: Colors.blue),
          title: Text(type, style: TextStyle(fontSize: 20)),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: Colors.blue)
              : null,
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (selectedType == 'Học Sinh') {
      final idHocSinh = LocalDataService.instance.getId();
      if (idHocSinh == null || idHocSinh.isEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => DangNhapHocSinhScreen()));
      } else {
        HocSinh? hocSinh = await HocSinhService.getHocSinhById(idHocSinh);
        if (hocSinh == null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => DangNhapHocSinhScreen()));
          return;
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainHocSinhScreen(hocSinh: hocSinh)));
        }
      }
    } else if (selectedType == 'Giáo Viên') {
      // Similar logic for teachers
      final idGiaoVien = LocalDataService.instance.getId();
      if (idGiaoVien == null || idGiaoVien.isEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => DangNhapGiaoVienScreen()));
      } else {
        final GiaoVien? giaoVien = await GiaoVienService.getGiaoVienById(idGiaoVien);
        if (giaoVien == null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => DangNhapGiaoVienScreen()));
          return;
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => MainGiaoVienScreen()));
        }
      }
    } else if (selectedType == 'Phụ huynh') {
      // Handle parent login similarly
      final idPhuHuynh = LocalDataService.instance.getId();
      if (idPhuHuynh == null || idPhuHuynh.isEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => DangNhapPhuHuynhScreen()));
      } else {
        final PhuHuynh? phuHuynh = await PhuHuynhService.getPhuHuynhById(idPhuHuynh);
        if (phuHuynh == null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => DangNhapPhuHuynhScreen()));
          return;
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => MainPhuHuynhScreen()));
        }
      }
    }
  }

  Future<void> _initializeApp() async {
    switch (localDataService.getRole()) {
      case null:
      // No role found, stay on auth screen
        break;
      case UserRole.admin:
        break;
      case UserRole.giaovien:
        break;
      case UserRole.phuhuynh:
        break;
      case UserRole.hocsinh:
        if (localDataService.getId() != null) {
          final HocSinh? hocSinh = await HocSinhService.getHocSinhById(localDataService.getId()!);
          if (mounted && hocSinh != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MainHocSinhScreen(hocSinh: hocSinh)),
            );
          }
        }
        break;
    }
  }
}
