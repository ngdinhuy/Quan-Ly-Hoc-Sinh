import 'package:flutter/material.dart';
import '../models/hoc_sinh.dart';
import '../services/hoc_sinh_service.dart';
import '../services/local_data_service.dart';
import 'hoc_sinh/dang_nhap_hoc_sinh/dang_nhap_screen.dart';

class ChonLoaiVaiTroScreen extends StatefulWidget {
  @override
  _ChonLoaiVaiTroScreenState createState() => _ChonLoaiVaiTroScreenState();
}

class _ChonLoaiVaiTroScreenState extends State<ChonLoaiVaiTroScreen> {
  String? selectedType;

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
      // Check if student ID exists in local storage
      final idHocSinh = LocalDataService.instance.getIdHocSinh();
      print('idHocSinh: $idHocSinh');
      if (idHocSinh == null || idHocSinh.isEmpty) {
        // If no ID found, navigate to login screen
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DangNhapHocSinhScreen()));
      } else {
        // ID exists, navigate to main student screen
        HocSinh? hocSinh = await HocSinhService.getHocSinhById(idHocSinh);
        if (hocSinh == null) {
          // If student data not found, navigate to login screen
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DangNhapHocSinhScreen()));
          return;
        }
      }
    } else if (selectedType == 'Giáo Viên') {
      // Similar logic for teachers
      final idGiaoVien = LocalDataService.instance.getIdGiaoVien();

      if (idGiaoVien == null || idGiaoVien.isEmpty) {
        Navigator.pushNamed(context, '/login_giao_vien');
      } else {
        Navigator.pushNamed(context, '/main_giao_vien');
      }
    }
  }
}
