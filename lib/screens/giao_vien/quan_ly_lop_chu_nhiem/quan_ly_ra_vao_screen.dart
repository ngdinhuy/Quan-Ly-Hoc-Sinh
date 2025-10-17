import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:quan_ly_hoc_sinh/screens/giao_vien/danh_sach_phu_huynh_tham/danh_sach_phu_huynh_tham_screen.dart';
import 'package:quan_ly_hoc_sinh/screens/giao_vien/danh_sach_ra_vao_theo_lop/danh_sach_ra_vao_theo_lop_screen.dart';
import 'package:quan_ly_hoc_sinh/services/local_data_service.dart';
import '../../../models/giao_vien.dart';
import '../../../models/lop.dart';
import '../../../models/phan_cong_chu_nhiem.dart';
import '../../../services/lop_service.dart';
import '../../../services/phan_cong_chu_nhiem_service.dart';

class QuanLyLopChuNhiemScreen extends StatefulWidget {
  final bool isQuanLyRaVao;
  const QuanLyLopChuNhiemScreen({Key? key, this.isQuanLyRaVao = true}) : super(key: key);

  @override
  State<QuanLyLopChuNhiemScreen> createState() => _QuanLyLopChuNhiemScreenState();
}

class _QuanLyLopChuNhiemScreenState extends State<QuanLyLopChuNhiemScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _classesWithInfo = [];
  String _errorMessage = '';
  GiaoVien? _currentTeacher;
  LocalDataService localDataService = LocalDataService.instance;

  @override
  void initState() {
    super.initState();
    _loadTeacherClasses();
  }

  Future<void> _loadTeacherClasses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get all homeroom assignments for this teacher
      List<PhanCongChuNhiem> assignments =
          await PhanCongChuNhiemService.getAll();
      assignments = assignments
          .where(
            (assignment) =>
                assignment.idGv == localDataService.getId() &&
                (assignment.denNgay == null ||
                    assignment.denNgay!.isAfter(DateTime.now())),
          )
          .toList();

      // For each assignment, get the class information
      final List<Map<String, dynamic>> classesWithInfo = [];

      for (var assignment in assignments) {
        final lop = await LopService.getLopById(assignment.idLop);
        if (lop != null) {
          classesWithInfo.add({'lop': lop, 'assignment': assignment});
        }
      }

      setState(() {
        _classesWithInfo = classesWithInfo;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading teacher classes: $e');
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách lớp chủ nhiệm')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadTeacherClasses,
        icon: const Icon(Icons.refresh),
        label: const Text('Làm mới'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTeacherClasses,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_classesWithInfo.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.class_, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Bạn chưa được phân công chủ nhiệm lớp nào',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTeacherClasses,
              child: const Text('Làm mới'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeacherClasses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _classesWithInfo.length,
        itemBuilder: (context, index) {
          final classInfo = _classesWithInfo[index];
          final lop = classInfo['lop'] as Lop;
          final assignment = classInfo['assignment'] as PhanCongChuNhiem;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _navigateToStudentEntryExit(lop),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lop.tenLop,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Mã: ${lop.maLop}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Sĩ số: ${lop.siSo} học sinh'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.room, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Phòng: ${lop.phongSo}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Phân công từ: ${DateFormat('dd/MM/yyyy').format(assignment.tuNgay)}',
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Xem thông tin ra vào'),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToStudentEntryExit(Lop lop) {
    debugPrint('Navigating to student entry/exit for class: ${lop.tenLop}');
    if (lop.id == null) return;
    if (widget.isQuanLyRaVao) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DanhSachRaVaoTheoLopScreen(idLop: lop.id!, tenLop: lop.tenLop,),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DanhSachPhuHuynhThamScreen(idLop: lop.id!, tenLop: lop.tenLop,),
        ),
      );
    }
  }
}
