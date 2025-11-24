import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/xin_ve_phep.dart';
import '../../../services/giao_vien_service.dart';
import '../../../services/local_data_service.dart';
import '../../../services/phan_cong_chu_nhiem_service.dart';
import '../../../services/phan_cong_truc_ban_service.dart';
import '../../../services/xin_ve_phep_service.dart';
import '../../../widgets/giao_vien_nhap_ve_phep_form_dialog.dart';
import '../../../widgets/xin_ve_phep_detail_dialog.dart';

class DuyetVePhepScreen extends StatefulWidget {
  const DuyetVePhepScreen({super.key});

  @override
  State<DuyetVePhepScreen> createState() => _DuyetVePhepScreenState();
}

class _DuyetVePhepScreenState extends State<DuyetVePhepScreen> {
  final LocalDataService _localDataService = LocalDataService.instance;
  bool _isDutyTeacher = false;
  String? _homeroomClassId;
  String? _teacherName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTeacherRole();
  }

  Future<void> _checkTeacherRole() async {
    final teacherId = _localDataService.getId();
    if (teacherId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Kiểm tra xem phải giáo viên trực ban k?
      final dutyAssignments = await PhanCongTrucBanService.getByTeacherId(
        teacherId,
      );
      final isDuty = dutyAssignments.isNotEmpty;

      // Kiểm tra xem phải giáo viên chủ nhiệm hay k?
      final homeroomClasses =
          await PhanCongChuNhiemService.getClassesByTeacherId(teacherId);
      final homeroomClassId = homeroomClasses.isNotEmpty
          ? homeroomClasses.first['assignment']['id_lop'] as String?
          : null;

      // Get teacher name
      final teacher = await GiaoVienService.getGiaoVienById(teacherId);
      final teacherName = teacher?.hoTen;

      setState(() {
        _isDutyTeacher = isDuty;
        _homeroomClassId = homeroomClassId;
        _teacherName = teacherName;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error checking teacher role: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Duyệt Về Phép'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isDutyTeacher && _homeroomClassId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Duyệt Về Phép'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Bạn không có quyền duyệt về phép',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Duyệt Về Phép'),
            Text(
              _isDutyTeacher
                  ? 'Giáo viên trực ban - Xem tất cả'
                  : 'Giáo viên chủ nhiệm - Lớp của bạn',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.add_circle_outline),
        //     tooltip: 'Tạo mới',
        //     onPressed: () {
        //       showDialog(
        //         context: context,
        //         builder: (context) => GiaoVienNhapVePhepFormDialog(
        //           teacherId: _localDataService.getId()!,
        //           teacherName: _teacherName ?? 'Giáo viên',
        //         ),
        //       ).then((result) {
        //         if (result == true) {
        //           // Refresh list if request was created
        //           setState(() {});
        //         }
        //       });
        //     },
        //   ),
        // ],
      ),
      body: StreamBuilder<List<XinVePhep>>(
        stream: _isDutyTeacher
            ? XinVePhepService.streamPendingApprovals()
            : XinVePhepService.streamPendingForTeacher(_homeroomClassId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có yêu cầu chờ duyệt',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(request);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(XinVePhep request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 3,
      child: InkWell(
        onTap: () => _showDetailAndApproval(request),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.hoTenHocSinh,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Lớp: ${request.tenLop} - Thẻ: ${request.soTheHocSinh}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      'Chờ duyệt',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.calendar_today,
                'Ngày về:',
                DateFormat('dd/MM/yyyy').format(request.ngayXinVe),
              ),
              if (request.ngayXuongTruong != null)
                _buildInfoRow(
                  Icons.event_available,
                  'Ngày về trường:',
                  DateFormat('dd/MM/yyyy').format(request.ngayXuongTruong!),
                ),
              _buildInfoRow(Icons.person, 'Người đón:', request.tenNguoiDon),
              _buildInfoRow(Icons.credit_card, 'CCCD:', request.cccdNguoiDon),
              _buildInfoRow(Icons.phone, 'SĐT:', request.sdtNguoiDon),
              if (request.danhSachNgayCatCom.isNotEmpty)
                _buildInfoRow(
                  Icons.restaurant,
                  'Cắt cơm:',
                  '${request.danhSachNgayCatCom.length} ngày',
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.lyDo,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(request),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Duyệt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(request),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _showDetailAndApproval(XinVePhep request) {
    showDialog(
      context: context,
      builder: (context) => XinVePhepDetailDialog(xinVePhep: request),
    );
  }

  Future<void> _approveRequest(XinVePhep request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt'),
        content: Text(
          'Bạn có chắc chắn muốn duyệt yêu cầu về phép của ${request.hoTenHocSinh}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final teacherId = _localDataService.getId();
      if (teacherId == null) return;

      await XinVePhepService.approve(
        request.id!,
        teacherId,
        _teacherName ?? 'Giáo viên',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã duyệt yêu cầu thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  Future<void> _rejectRequest(XinVePhep request) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Từ chối yêu cầu của ${request.hoTenHocSinh}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final teacherId = _localDataService.getId();
      if (teacherId == null) return;

      await XinVePhepService.reject(
        request.id!,
        reasonController.text.trim(),
        teacherId,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã từ chối yêu cầu')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      reasonController.dispose();
    }
  }
}
