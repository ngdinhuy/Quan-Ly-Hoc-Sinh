import 'package:flutter/material.dart';
import '../models/phu_huynh.dart';
import '../models/tham_ph.dart';
import '../models/hoc_sinh.dart';
import '../models/lop.dart';
import '../services/phu_huynh_service.dart';
import '../services/tham_ph_service.dart';
import '../services/hoc_sinh_service.dart';
import '../services/lop_service.dart';
import '../widgets/phu_huynh_form_dialog.dart';
import '../widgets/tham_ph_form_dialog.dart';

class PhuHuynhScreen extends StatefulWidget {
  const PhuHuynhScreen({super.key});

  @override
  State<PhuHuynhScreen> createState() => _PhuHuynhScreenState();
}

class _PhuHuynhScreenState extends State<PhuHuynhScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<PhuHuynh> _phuHuynhList = [];
  List<ThamPh> _thamPhList = [];
  List<HocSinh> _hocSinhList = [];
  List<Lop> _lopList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final lopList = await LopService.getAllLop(); // Load all classes
      setState(() {
        _lopList = lopList;
      });

      if (lopList.isNotEmpty) {
        await _loadHocSinhByLop(lopList.first.id!);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHocSinhByLop(String idLop) async {
    try {
      final hocSinhList = await HocSinhService.getHocSinhByLop(idLop);
      setState(() {
        _hocSinhList = hocSinhList;
      });

      if (hocSinhList.isNotEmpty) {
        await _loadPhuHuynhByHs(hocSinhList.first.id!);
        await _loadThamPhByHs(hocSinhList.first.id!);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách học sinh: $e')));
    }
  }

  Future<void> _loadPhuHuynhByHs(String idHs) async {
    try {
      final phuHuynhList = await PhuHuynhService.getPhuHuynhByHs(idHs);
      setState(() {
        _phuHuynhList = phuHuynhList;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách phụ huynh: $e')),
      );
    }
  }

  Future<void> _loadThamPhByHs(String idHs) async {
    try {
      final thamPhList = await ThamPhService.getThamPhByHs(idHs);
      setState(() {
        _thamPhList = thamPhList;
      });
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách thăm phụ huynh: $e')),
      );
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
            'Quản Lý Phụ Huynh',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_lopList.isNotEmpty)
                DropdownButton<Lop>(
                  value: _lopList.isNotEmpty ? _lopList.first : null,
                  hint: const Text('Chọn lớp'),
                  items:
                      _lopList.map((lop) {
                        return DropdownMenuItem(
                          value: lop,
                          child: Text(lop.tenLop),
                        );
                      }).toList(),
                  onChanged: (lop) {
                    if (lop != null) {
                      _loadHocSinhByLop(lop.id!);
                    }
                  },
                ),
              const SizedBox(width: 16),
              if (_hocSinhList.isNotEmpty)
                DropdownButton<HocSinh>(
                  value: _hocSinhList.isNotEmpty ? _hocSinhList.first : null,
                  hint: const Text('Chọn học sinh'),
                  items:
                      _hocSinhList.map((hocSinh) {
                        return DropdownMenuItem(
                          value: hocSinh,
                          child: Text(
                            '${hocSinh.hoTen} - ${hocSinh.soTheHocSinh}',
                          ),
                        );
                      }).toList(),
                  onChanged: (hocSinh) {
                    if (hocSinh != null) {
                      _loadPhuHuynhByHs(hocSinh.id!);
                      _loadThamPhByHs(hocSinh.id!);
                    }
                  },
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
                    Tab(text: 'Phụ Huynh', icon: Icon(Icons.family_restroom)),
                    Tab(text: 'Thăm Con', icon: Icon(Icons.people)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildPhuHuynhTab(), _buildThamPhTab()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhuHuynhTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh Sách Phụ Huynh',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed:
                    _hocSinhList.isNotEmpty
                        ? () => _showPhuHuynhFormDialog()
                        : null,
                icon: const Icon(Icons.add),
                label: const Text('Thêm Phụ Huynh'),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _phuHuynhList.isEmpty
                  ? const Center(
                    child: Text(
                      'Chưa có phụ huynh nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                  : Card(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Họ Tên')),
                        DataColumn(label: Text('Số CCCD')),
                        DataColumn(label: Text('Số ĐT')),
                        DataColumn(label: Text('Quan Hệ')),
                        DataColumn(label: Text('Thao Tác')),
                      ],
                      rows:
                          _phuHuynhList.map((phuHuynh) {
                            return DataRow(
                              cells: [
                                DataCell(Text(phuHuynh.hoTen)),
                                DataCell(Text(phuHuynh.soCccd)),
                                DataCell(Text(phuHuynh.soDienThoai)),
                                DataCell(Text(phuHuynh.quanHe)),
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
                                            () => _showPhuHuynhFormDialog(
                                              phuHuynh: phuHuynh,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _deletePhuHuynh(phuHuynh),
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
      ],
    );
  }

  Widget _buildThamPhTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh Sách Thăm Con',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed:
                    _hocSinhList.isNotEmpty
                        ? () => _showThamPhFormDialog()
                        : null,
                icon: const Icon(Icons.add),
                label: const Text('Thêm Thăm Con'),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _thamPhList.isEmpty
                  ? const Center(
                    child: Text(
                      'Chưa có lịch thăm con nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                  : Card(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Phụ Huynh')),
                        DataColumn(label: Text('Học Sinh')),
                        DataColumn(label: Text('Thời Gian Đến')),
                        DataColumn(label: Text('Thời Gian Kết Thúc')),
                        DataColumn(label: Text('Trạng Thái')),
                        DataColumn(label: Text('Thao Tác')),
                      ],
                      rows:
                          _thamPhList.map((thamPh) {
                            return DataRow(
                              cells: [
                                DataCell(Text(thamPh.hoTenPh)),
                                DataCell(Text(thamPh.hoTenHs)),
                                DataCell(
                                  Text(_formatDateTime(thamPh.thoiGianDen)),
                                ),
                                DataCell(
                                  Text(
                                    thamPh.thoiGianKetThuc != null
                                        ? _formatDateTime(
                                          thamPh.thoiGianKetThuc!,
                                        )
                                        : 'Chưa kết thúc',
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          thamPh.trangThai ==
                                                  TrangThaiTham.dangTham
                                              ? Colors.green
                                              : Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      thamPh.trangThai == TrangThaiTham.dangTham
                                          ? 'Đang thăm'
                                          : 'Đã về',
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
                                            () => _showThamPhFormDialog(
                                              thamPh: thamPh,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteThamPh(thamPh),
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
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showPhuHuynhFormDialog({PhuHuynh? phuHuynh}) {
    if (_hocSinhList.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => PhuHuynhFormDialog(
            hocSinh: _hocSinhList.first,
            phuHuynh: phuHuynh,
            onSaved: () {
              _loadPhuHuynhByHs(_hocSinhList.first.id!);
            },
          ),
    );
  }

  void _showThamPhFormDialog({ThamPh? thamPh}) {
    if (_hocSinhList.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => ThamPhFormDialog(
            hocSinh: _hocSinhList.first,
            thamPh: thamPh,
            onSaved: () {
              _loadThamPhByHs(_hocSinhList.first.id!);
            },
          ),
    );
  }

  void _deletePhuHuynh(PhuHuynh phuHuynh) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác Nhận Xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa phụ huynh "${phuHuynh.hoTen}"?',
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
                    await PhuHuynhService.deletePhuHuynh(phuHuynh.id!);
                    _loadPhuHuynhByHs(_hocSinhList.first.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Xóa phụ huynh thành công'),
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

  void _deleteThamPh(ThamPh thamPh) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác Nhận Xóa'),
            content: Text('Bạn có chắc chắn muốn xóa lịch thăm con này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ThamPhService.deleteThamPh(thamPh.id!);
                    _loadThamPhByHs(_hocSinhList.first.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Xóa lịch thăm con thành công'),
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
