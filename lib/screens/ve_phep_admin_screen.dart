import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/xin_ve_phep.dart';
import '../models/lop.dart';
import '../services/xin_ve_phep_service.dart';
import '../services/lop_service.dart';
import '../services/phan_cong_chu_nhiem_service.dart';
import '../widgets/giao_vien_nhap_ve_phep_form_dialog.dart';
import '../widgets/xin_ve_phep_detail_dialog.dart';

class VePhepAdminScreen extends StatefulWidget {
  const VePhepAdminScreen({super.key});

  @override
  State<VePhepAdminScreen> createState() => _VePhepAdminScreenState();
}

class _VePhepAdminScreenState extends State<VePhepAdminScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<XinVePhep> _xinVePhepList = [];
  List<Lop> _lopList = [];
  Lop? _lop;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lopList = await LopService.getAllLop();
      setState(() {
        _lopList = lopList;
      });

      if (lopList.isNotEmpty) {
        await _loadXinVePhepByLop(lopList.first.id!);
      }
    } catch (e) {
      if (mounted) {
        debugPrint("huynd ${e}");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadXinVePhepByLop(String idLop) async {
    try {
      final xinVePhepList = await XinVePhepService.getXinVePhepByLop(idLop);
      setState(() {
        _xinVePhepList = xinVePhepList;
      });
    } catch (e) {
      if (mounted) {
        debugPrint("huynd ${e}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách về phép: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản Lý Về Phép',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_lopList.isNotEmpty)
                DropdownButton<Lop>(
                  value: _lop ?? (_lopList.isNotEmpty ? _lopList.first : null),
                  hint: const Text('Chọn lớp'),
                  items: _lopList.map((lop) {
                    return DropdownMenuItem(
                      value: lop,
                      child: Text(lop.tenLop),
                    );
                  }).toList(),
                  onChanged: (lop) {
                    setState(() {
                      _lop = lop;
                    });
                    if (lop != null) {
                      _loadXinVePhepByLop(lop.id!);
                    }
                  },
                ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _lopList.isNotEmpty
                    ? () => _createNewRequest()
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Thêm Yêu Cầu'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Chờ Duyệt', icon: Icon(Icons.pending)),
                    Tab(text: 'Đã Duyệt', icon: Icon(Icons.check)),
                    Tab(text: 'Từ Chối', icon: Icon(Icons.cancel)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVePhepList(TrangThaiVePhep.choDuyet),
                      _buildVePhepList(TrangThaiVePhep.daDuyet),
                      _buildVePhepList(TrangThaiVePhep.tuChoi),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVePhepList(TrangThaiVePhep trangThai) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredList = _xinVePhepList
        .where((xin) => xin.trangThai == trangThai)
        .toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          'Không có yêu cầu nào',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Card(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Học Sinh')),
              DataColumn(label: Text('Số Thẻ')),
              DataColumn(label: Text('Ngày về')),
              DataColumn(label: Text('Ngày xuống trường')),
              DataColumn(label: Text('Người đón')),
              DataColumn(label: Text('Lý do')),
              DataColumn(label: Text('Thao Tác')),
            ],
            rows: filteredList.map((xin) {
              return DataRow(
                cells: [
                  DataCell(Text(xin.hoTenHocSinh)),
                  DataCell(Text(xin.soTheHocSinh)),
                  DataCell(Text(_formatDate(xin.ngayXinVe))),
                  DataCell(
                    Text(
                      xin.ngayXuongTruong != null
                          ? _formatDate(xin.ngayXuongTruong!)
                          : '-',
                    ),
                  ),
                  DataCell(Text(xin.tenNguoiDon)),
                  DataCell(Text(_truncateText(xin.lyDo, 30))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (trangThai == TrangThaiVePhep.choDuyet) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 20,
                            ),
                            onPressed: () => _approveRequest(xin),
                            tooltip: 'Duyệt',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () => _rejectRequest(xin),
                            tooltip: 'Từ chối',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                        ],
                        IconButton(
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.blue,
                            size: 20,
                          ),
                          onPressed: () => _viewDetails(xin),
                          tooltip: 'Xem chi tiết',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.orange,
                            size: 20,
                          ),
                          onPressed: () => _editRequest(xin),
                          tooltip: 'Chỉnh sửa',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _deleteRequest(xin),
                          tooltip: 'Xóa',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _getNguonText(XinVePhep xin) {
    switch (xin.nguon) {
      case NguonVePhep.appPhuHuynh:
        return xin.tenPhuHuynh != null ? 'PH: ${xin.tenPhuHuynh}' : 'Phụ huynh';
      case NguonVePhep.appHocSinh:
        return 'Học sinh';
      case NguonVePhep.giaoVienNhap:
        return 'GV nhập';
    }
  }

  void _viewDetails(XinVePhep request) {
    showDialog(
      context: context,
      builder: (context) => XinVePhepDetailDialog(xinVePhep: request),
    );
  }

  Future<void> _createNewRequest() async {
    if (_lopList.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn lớp')));
      return;
    }

    final selectedLop = _lop ?? _lopList.first;
    debugPrint("huynd lop.id ${selectedLop.id}");
    // Get homeroom teacher for the selected class
    final teacherInfo = await PhanCongChuNhiemService.getTeacherByClassId(
      selectedLop.id!,
    );
    debugPrint("huynd teacherInfo.id ${teacherInfo?.id}");

    if (teacherInfo == null || teacherInfo.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy giáo viên chủ nhiệm của lớp'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => GiaoVienNhapVePhepFormDialog(
        teacherId: teacherInfo.id!,
        teacherName: teacherInfo.hoTen,
        idLop: selectedLop.id!,
      ),
    ).then((result) {
      if (result == true) {
        // Reload data after creating
        _loadXinVePhepByLop(_lop?.id ?? _lopList.first.id!);
      }
    });
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
      // Get homeroom teacher for the student's class
      final teacherInfo = await PhanCongChuNhiemService.getTeacherByClassId(
        request.idLop,
      );
      if (teacherInfo == null) {
        throw Exception('Không tìm thấy giáo viên chủ nhiệm của lớp');
      }

      await XinVePhepService.approve(
        request.id!,
        teacherInfo.id!,
        teacherInfo.hoTen,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã duyệt yêu cầu thành công')),
        );
        _loadXinVePhepByLop(_lop?.id ?? _lopList.first.id!);
      }
    } catch (e) {
      if (mounted) {
        debugPrint("huynd ${e}");
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

    if (confirm != true) {
      reasonController.dispose();
      return;
    }

    try {
      // Admin rejects directly without needing teacher ID
      await XinVePhepService.reject(
        request.id!,
        reasonController.text.trim(),
        'admin',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã từ chối yêu cầu')));
        _loadXinVePhepByLop(_lop?.id ?? _lopList.first.id!);
      }
    } catch (e) {
      debugPrint("huynd $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      reasonController.dispose();
    }
  }

  Future<void> _editRequest(XinVePhep request) async {
    if (!mounted) return;

    // Admin edits directly without needing teacher ID
    showDialog(
      context: context,
      builder: (context) => GiaoVienNhapVePhepFormDialog(
        teacherId: 'admin',
        teacherName: 'Admin',
        xinVePhep: request,
        idLop: request.idLop,
      ),
    ).then((result) {
      if (result == true) {
        // Reload data after editing
        _loadXinVePhepByLop(_lop?.id ?? _lopList.first.id!);
      }
    });
  }

  Future<void> _deleteRequest(XinVePhep request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa yêu cầu của ${request.hoTenHocSinh}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await XinVePhepService.deleteXinVePhep(request.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa yêu cầu thành công')),
        );
        _loadXinVePhepByLop(_lop?.id ?? _lopList.first.id!);
      }
    } catch (e) {
      debugPrint("huynd ${e}");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }
}
