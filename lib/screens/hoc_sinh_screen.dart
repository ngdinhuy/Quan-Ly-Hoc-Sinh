import 'package:flutter/material.dart';
import '../models/hoc_sinh.dart';
import '../models/truong.dart';
import '../models/lop.dart';
import '../services/hoc_sinh_service.dart';
import '../services/truong_service.dart';
import '../services/lop_service.dart';
import '../widgets/hoc_sinh_form_dialog.dart';

class HocSinhScreen extends StatefulWidget {
  const HocSinhScreen({super.key});

  @override
  State<HocSinhScreen> createState() => _HocSinhScreenState();
}

class _HocSinhScreenState extends State<HocSinhScreen> {
  Truong? _selectedTruong;
  List<Truong> _truongList = [];
  List<Lop> _lopList = [];
  Lop? _selectedLop;
  List<HocSinh> _hocSinhList = [];

  @override
  void initState() {
    super.initState();
    _loadTruongList();
  }

  Future<void> _loadTruongList() async {
    try {
      final truongList = await TruongService.getAllTruong();
      setState(() {
        _truongList = truongList;
        if (truongList.isNotEmpty) {
          _selectedTruong = truongList.first;
          _loadLopList();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách trường: $e')));
    }
  }

  Future<void> _loadLopList() async {
    if (_selectedTruong == null) return;

    try {
      final lopList = await LopService.getLopByTruong(_selectedTruong!.id!);
      setState(() {
        _lopList = lopList;
        if (lopList.isNotEmpty) {
          _loadHocSinhList(_selectedLop?.id ?? lopList.first.id!);
        }
      });
    } catch (e) {
      debugPrint("huynd $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách lớp: $e')));
    }
  }

  Future<void> _loadHocSinhList(String idLop) async {
    try {
      final hocSinhList = await HocSinhService.getHocSinhByLop(idLop);
      setState(() {
        _hocSinhList = hocSinhList;
      });
    } catch (e) {
      debugPrint("huynd $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách học sinh: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Quản Lý Học Sinh',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 32),
              if (_truongList.isNotEmpty)
                DropdownButton<Truong>(
                  value: _selectedTruong,
                  hint: const Text('Chọn trường'),
                  items:
                      _truongList.map((truong) {
                        return DropdownMenuItem(
                          value: truong,
                          child: Text(truong.tenTruong),
                        );
                      }).toList(),
                  onChanged: (truong) {
                    setState(() {
                      _selectedTruong = truong;
                    });
                    _loadLopList();
                  },
                ),
              const SizedBox(width: 16),
              if (_lopList.isNotEmpty)
                DropdownButton<Lop>(
                  value:
                      _selectedLop ??
                      (_lopList.isNotEmpty ? _lopList.first : null),
                  hint: const Text('Chọn lớp'),
                  items:
                      _lopList.map((lop) {
                        return DropdownMenuItem(
                          value: lop,
                          child: Text(lop.tenLop),
                        );
                      }).toList(),
                  onChanged: (lop) {
                    setState(() {
                      _selectedLop = lop;
                    });
                    if (lop != null) {
                      _loadHocSinhList(lop.id!);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Danh Sách Học Sinh ${_selectedLop?.tenLop ?? (_lopList.isNotEmpty ? ' - ${_lopList.first.tenLop}' : '')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed:
                    _selectedTruong != null && _selectedLop != null
                        ? () => _showHocSinhFormDialog()
                        : null,
                icon: const Icon(Icons.add),
                label: const Text('Thêm Học Sinh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                _selectedTruong == null || _lopList.isEmpty
                    ? const Center(
                      child: Text(
                        'Vui lòng chọn trường và lớp',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : _hocSinhList.isEmpty
                    ? const Center(
                      child: Text(
                        'Chưa có học sinh nào trong lớp này',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : Card(
                      clipBehavior: Clip.antiAlias,
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Scrollbar(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('Họ Tên')),
                                  DataColumn(label: Text('Số Thẻ')),
                                  DataColumn(label: Text('Số ĐT')),
                                  DataColumn(label: Text('Phòng Số')),
                                  DataColumn(label: Text('Trạng Thái')),
                                  DataColumn(label: Text('Thao Tác')),
                                ],
                                rows:
                                    _hocSinhList.map((hocSinh) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(hocSinh.id ?? "")),
                                          DataCell(Text(hocSinh.hoTen)),
                                          DataCell(Text(hocSinh.soTheHocSinh)),
                                          DataCell(
                                            Text(hocSinh.soDienThoai ?? ''),
                                          ),
                                          DataCell(Text(hocSinh.phongSo)),
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                  hocSinh.trangThai,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _getStatusText(
                                                  hocSinh.trangThai,
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                  ),
                                                  onPressed:
                                                      () =>
                                                          _showHocSinhFormDialog(
                                                            hocSinh: hocSinh,
                                                          ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed:
                                                      () => _deleteHocSinh(
                                                        hocSinh,
                                                      ),
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
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TrangThaiHocSinh trangThai) {
    switch (trangThai) {
      case TrangThaiHocSinh.dangHoc:
        return Colors.green;
      case TrangThaiHocSinh.tamNghi:
        return Colors.orange;
      case TrangThaiHocSinh.nghiHoc:
        return Colors.red;
    }
  }

  String _getStatusText(TrangThaiHocSinh trangThai) {
    switch (trangThai) {
      case TrangThaiHocSinh.dangHoc:
        return 'Đang học';
      case TrangThaiHocSinh.tamNghi:
        return 'Tạm nghỉ';
      case TrangThaiHocSinh.nghiHoc:
        return 'Nghỉ học';
    }
  }

  void _showHocSinhFormDialog({HocSinh? hocSinh}) {
    if (_selectedTruong == null || _lopList.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => HocSinhFormDialog(
            truong: _selectedTruong!,
            lop: _selectedLop ?? _lopList.first,
            hocSinh: hocSinh,
            onSaved: () {
              _loadHocSinhList(_selectedLop?.id ?? _lopList.first.id!);
            },
          ),
    );
  }

  void _deleteHocSinh(HocSinh hocSinh) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác Nhận Xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa học sinh "${hocSinh.hoTen}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await HocSinhService.deleteHocSinh(hocSinh.id!);
                    _loadHocSinhList(_selectedLop?.id ?? _lopList.first.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Xóa học sinh thành công'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  }
                },
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
  }
}
