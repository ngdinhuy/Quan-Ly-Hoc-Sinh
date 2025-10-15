import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:quan_ly_hoc_sinh/models/phan_cong_chu_nhiem.dart';
import 'package:quan_ly_hoc_sinh/models/giao_vien.dart';
import 'package:quan_ly_hoc_sinh/models/lop.dart';
import 'package:quan_ly_hoc_sinh/services/phan_cong_chu_nhiem_service.dart';
import 'package:quan_ly_hoc_sinh/services/giao_vien_service.dart';
import 'package:quan_ly_hoc_sinh/services/lop_service.dart';
import 'package:quan_ly_hoc_sinh/widgets/phan_cong_form_dialog.dart';

class PhanCongChuNhiemScreen extends StatefulWidget {
  const PhanCongChuNhiemScreen({Key? key}) : super(key: key);

  @override
  State<PhanCongChuNhiemScreen> createState() => _PhanCongChuNhiemScreenState();
}

class _PhanCongChuNhiemScreenState extends State<PhanCongChuNhiemScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assignmentData = [];
  String? _selectedYear;
  List<String> _schoolYears = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get all assignments
      List<PhanCongChuNhiem> assignments = await PhanCongChuNhiemService.getAll();

      // Extract unique school years for filtering
      Set<String> schoolYearSet = {};

      List<Map<String, dynamic>> tempData = [];

      for (var assignment in assignments) {
        // Get teacher details
        GiaoVien? teacher = await GiaoVienService.getGiaoVienById(assignment.idGv);

        // Get class details
        Lop? classInfo = await LopService.getLopById(assignment.idLop);

        if (teacher != null && classInfo != null) {
          // Add to school years filter
          if (classInfo.tenLop.contains('-')) {
            String year = classInfo.tenLop.split('-').last.trim();
            schoolYearSet.add(year);
          }

          // Create combined data object
          Map<String, dynamic> item = {
            'assignment': assignment,
            'teacher': teacher,
            'class': classInfo,
          };

          // Filter by selected year if applicable
          if (_selectedYear == null ||
              classInfo.tenLop.contains(_selectedYear!)) {
            tempData.add(item);
          }
        }
      }

      setState(() {
        _assignmentData = tempData;
        _schoolYears = schoolYearSet.toList()..sort();
        if (_schoolYears.isNotEmpty && _selectedYear == null) {
          _selectedYear = _schoolYears.last; // Default to latest year
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
    }
  }

  void _applyYearFilter(String? year) {
    setState(() {
      _selectedYear = year;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân công chủ nhiệm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignmentData.isEmpty
          ? const Center(child: Text('Không có dữ liệu phân công'))
          : Column(
        children: [
          if (_selectedYear != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text('Năm học: $_selectedYear'),
                deleteIcon: const Icon(Icons.close),
                onDeleted: () {
                  setState(() {
                    _selectedYear = null;
                  });
                  _loadData();
                },
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _assignmentData.length,
              itemBuilder: (context, index) {
                final item = _assignmentData[index];
                final teacher = item['teacher'] as GiaoVien;
                final classInfo = item['class'] as Lop;
                final assignment = item['assignment'] as PhanCongChuNhiem;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Lớp ${classInfo.tenLop}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Phòng: ${classInfo.phongSo}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        _buildInfoRow(
                          Icons.person,
                          'Giáo viên:',
                          teacher.hoTen,
                        ),
                        _buildInfoRow(
                          Icons.cake,
                          'Ngày sinh:',
                          teacher.ngaySinh != null
                              ? DateFormat('dd/MM/yyyy').format(teacher.ngaySinh!)
                              : 'Không có thông tin',
                        ),
                        _buildInfoRow(
                          Icons.phone,
                          'Số điện thoại:',
                          teacher.soDienThoai,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Bắt đầu:',
                          DateFormat('dd/MM/yyyy').format(assignment.tuNgay),
                        ),
                        _buildInfoRow(
                          Icons.event_available,
                          'Kết thúc:',
                          assignment.denNgay != null
                              ? DateFormat('dd/MM/yyyy').format(assignment.denNgay!)
                              : 'Hiện tại',
                        ),
                        if (assignment.ghiChu != null && assignment.ghiChu!.isNotEmpty)
                          _buildInfoRow(
                            Icons.note,
                            'Ghi chú:',
                            assignment.ghiChu!,
                          ),
                        ButtonBar(
                          alignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _editAssignment(assignment);
                              },
                              child: const Text('Chỉnh sửa'),
                            ),
                            TextButton(
                              onPressed: () {
                                _confirmDelete(assignment);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context, builder: (context) => const PhanCongFormDialog())
          .then((_) => _loadData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo năm học'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Tất cả'),
                selected: _selectedYear == null,
                onTap: () {
                  Navigator.pop(context);
                  _applyYearFilter(null);
                },
              ),
              ..._schoolYears.map((year) => ListTile(
                title: Text(year),
                selected: _selectedYear == year,
                onTap: () {
                  Navigator.pop(context);
                  _applyYearFilter(year);
                },
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _editAssignment(PhanCongChuNhiem assignment) {
    showDialog(context: context, builder: (context) => PhanCongFormDialog(initialAssignment: assignment))
        .then((_) => _loadData());
  }

  void _confirmDelete(PhanCongChuNhiem assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa phân công này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await PhanCongChuNhiemService.delete(assignment.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa phân công thành công')),
                );
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi khi xóa: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
