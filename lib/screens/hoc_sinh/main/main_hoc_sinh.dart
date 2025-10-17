import 'package:flutter/material.dart';
import 'package:quan_ly_hoc_sinh/screens/hoc_sinh/dang_ky_ra_ngoai/dang_ky_ra_ngoai_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/hoc_sinh/lich_su_ra_vao/lich_su_ra_vao_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/hoc_sinh/xac_thuc_khuon_mat/xac_thuc_khuon_mat_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/hoc_sinh/xac_thuc_the/xac_thuc_the_screen.dart';
import '../../../models/hoc_sinh.dart';

class MainHocSinhScreen extends StatefulWidget {
  final HocSinh hocSinh;

  const MainHocSinhScreen({Key? key, required this.hocSinh}) : super(key: key);

  @override
  _MainHocSinhScreenState createState() => _MainHocSinhScreenState();
}

class _MainHocSinhScreenState extends State<MainHocSinhScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chính'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Handle logout
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStudentInfoCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade200,
                backgroundImage: widget.hocSinh.avatarTheUrl != null
                    ? NetworkImage(widget.hocSinh.avatarTheUrl!)
                    : null,
                child: widget.hocSinh.avatarTheUrl == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.person, "Họ tên", widget.hocSinh.hoTen),
            _infoRow(Icons.cake, "Ngày sinh", _formatDate(widget.hocSinh.ngaySinh)),
            _infoRow(Icons.credit_card, "Số thẻ học sinh", widget.hocSinh.soTheHocSinh),
            _infoRow(Icons.class_, "Lớp", widget.hocSinh.phongSo),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _actionButton(
            "Đăng ký ra ngoài",
            Icons.exit_to_app,
            Colors.blue,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DangKyRaNgoaiScreen())),
          ),
          // const SizedBox(height: 16),
          // _actionButton(
          //   "Quét khuôn mặt",
          //   Icons.face,
          //   Colors.blue.shade700,
          //       () {
          //         Navigator.push(context, MaterialPageRoute(builder: (context) => const XacThucKhuonMatScreen()));
          //   },
          // ),
          const SizedBox(height: 16),
          _actionButton(
            "Lịch sử ra vào",
            Icons.history,
            Colors.blue.shade500,
                () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LichSuRaVaoScreen()));
              // Navigate to history screen
            },
          ),
          const SizedBox(height: 16),
          _actionButton(
            "Cập nhật khuôn mặt",
            Icons.face,
            Colors.blue.shade700,
                () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const XacThucKhuonMatScreen(isUploadFace: true,)));
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
