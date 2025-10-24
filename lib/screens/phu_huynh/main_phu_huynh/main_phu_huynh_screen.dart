import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quan_ly_hoc_sinh/screens/giao_vien/danh_sach_phu_huynh_tham/danh_sach_phu_huynh_tham_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/phu_huynh/dang_ky_tham_con/dang_ky_tham_con_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/phu_huynh/danh_sach_tham_con/danh_sach_tham_con_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/phu_huynh/hoc_sinh_ra_ngoai/hoc_sinh_ra_ngoai_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/phu_huynh/hoc_sinh_ra_ngoai_screen/hoc_sinh_ra_ngoai_screen.dart';
import 'package:quan_ly_hoc_sinh/services/local_data_service.dart';
import '../../../models/phu_huynh.dart';
import '../../../models/hoc_sinh.dart';
import '../../../services/phu_huynh_service.dart';
import '../../../services/hoc_sinh_service.dart';

class MainPhuHuynhScreen extends StatefulWidget {
  const MainPhuHuynhScreen({super.key});

  @override
  State<MainPhuHuynhScreen> createState() => _MainPhuHuynhScreenState();
}

class _MainPhuHuynhScreenState extends State<MainPhuHuynhScreen> {
  bool _isLoading = true;
  PhuHuynh? _phuHuynh;
  HocSinh? _hocSinh;
  String? _errorMessage;

  final LocalDataService loacalDateService = LocalDataService.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get parent information
      final PhuHuynh? fetchPhuHuynh = await PhuHuynhService.getPhuHuynhById(
        loacalDateService.getId()!,
      );

      if (fetchPhuHuynh == null) {
        throw Exception("Không tìm thấy thông tin phụ huynh");
      }

      final phuHuynh = fetchPhuHuynh;

      // Get student information
      final hocSinh = await HocSinhService.getHocSinhById(phuHuynh.idHs);

      if (hocSinh == null) {
        throw Exception("Không tìm thấy thông tin học sinh");
      }

      setState(() {
        _phuHuynh = phuHuynh;
        _hocSinh = hocSinh;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Trang chủ")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Trang chủ")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                "Đã xảy ra lỗi",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang chủ"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: "Làm mới",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: "Đăng xuất",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildParentCard(),
                const SizedBox(height: 24),
                _buildStudentCard(),
                const SizedBox(height: 24),
                _buildActionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParentCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  radius: 36,
                  child: const Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _phuHuynh!.hoTen,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Phụ huynh (${_phuHuynh!.quanHe})",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.credit_card, "CCCD:", _phuHuynh!.soCccd),
            _buildInfoRow(Icons.phone, "Số điện thoại:", _phuHuynh!.soDienThoai),
            _buildInfoRow(Icons.email, "Email:", _phuHuynh!.gmail),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  radius: 36,
                  child: _hocSinh!.avatarFaceUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _hocSinh!.avatarFaceUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.school, size: 40, color: Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hocSinh!.hoTen,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Học sinh",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.badge, "Mã số học sinh:", _hocSinh!.id ?? ""),
            _buildInfoRow(Icons.credit_card, "Số thẻ:", _hocSinh!.soTheHocSinh),
            _buildInfoRow(Icons.cake, "Ngày sinh:", _formatDate(_hocSinh!.ngaySinh)),
            _buildInfoRow(Icons.location_on, "Phòng:", _hocSinh!.phongSo),
            _buildStudentStatusChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentStatusChip() {
    Color color;
    String statusText;

    switch (_hocSinh!.trangThai) {
      case TrangThaiHocSinh.dangHoc:
        color = Colors.green;
        statusText = "Đang học";
        break;
      case TrangThaiHocSinh.tamNghi:
        color = Colors.orange;
        statusText = "Tạm nghỉ";
        break;
      case TrangThaiHocSinh.nghiHoc:
        color = Colors.red;
        statusText = "Nghỉ học";
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tác vụ",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: "Lịch sử thăm con",
          description: "Xem danh sách các lần đến thăm con",
          icon: Icons.history,
          color: Colors.blue,
          onTap: () => _navigateToVisitHistory(),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: "Đăng ký thăm con",
          description: "Đăng ký lịch thăm con tại trường",
          icon: Icons.calendar_month,
          color: Colors.green,
          onTap: () {
            _navigateToRegisterVisit();
          },
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: "Lịch sử ra vào của con",
          description: "Xem lịch sử ra vào của con",
          icon: Icons.calendar_month,
          color: Colors.green,
          onTap: () {
            _navigateToHistoryRaVao();
          },
        ),
        const SizedBox(height: 16,),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                foregroundColor: color,
                radius: 24,
                child: Icon(icon, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToVisitHistory() {
    if (_hocSinh != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DanhSachThamConScreen(
            idHocSinh: _hocSinh!.id!,
            tenHocSinh: _hocSinh!.hoTen,
          ),
        ),
      );
    }
  }

  void _navigateToRegisterVisit() {
    if (_hocSinh != null && loacalDateService.getId() != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DangKyThamConScreen(
            idHocSinh: _hocSinh!.id!,
            idPhuHuynh: loacalDateService.getId()!,
          ),
        ),
      );
    }
  }

  void _navigateToHistoryRaVao() {
    if (_hocSinh != null && loacalDateService.getId() != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HocSinhRaNgoaiScreen(idHocSinh: _hocSinh!.id!, tenHocSinh: _hocSinh!.hoTen)),
      );
    }
  }


  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to login screen or handle in auth state changes
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đăng xuất: $e")),
      );
    }
  }
}