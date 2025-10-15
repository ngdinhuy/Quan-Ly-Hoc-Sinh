import 'package:flutter/material.dart';
import '../models/truong.dart';
import '../models/khoi.dart';
import '../models/lop.dart';
import '../services/truong_service.dart';
import '../services/khoi_service.dart';
import '../services/lop_service.dart';
import '../widgets/khoi_form_dialog.dart';
import '../widgets/lop_form_dialog.dart';

class KhoiLopScreen extends StatefulWidget {
  const KhoiLopScreen({super.key});

  @override
  State<KhoiLopScreen> createState() => _KhoiLopScreenState();
}

class _KhoiLopScreenState extends State<KhoiLopScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Truong? _selectedTruong;
  List<Truong> _truongList = [];
  List<Khoi> _khoiList = [];
  List<Lop> _lopList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTruongList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTruongList() async {
    try {
      final truongList = await TruongService.getAllTruong();
      setState(() {
        _truongList = truongList;
        if (truongList.isNotEmpty) {
          _selectedTruong = truongList.first;
          _loadKhoiList();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách trường: $e')));
    }
  }

  Future<void> _loadKhoiList() async {
    if (_selectedTruong == null) return;

    try {
      final khoiList = await KhoiService.getKhoiByTruong(_selectedTruong!.id!);
      setState(() {
        _khoiList = khoiList;
      });
    } catch (e) {
      debugPrint("huynd $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách khối: $e')));
    }
  }

  Future<void> _loadLopList() async {
    if (_selectedTruong == null) return;

    try {
      final lopList = await LopService.getLopByTruong(_selectedTruong!.id!);
      setState(() {
        _lopList = lopList;
      });
    } catch (e) {
      debugPrint("huynd $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách lớp: $e')));
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
                'Quản Lý Khối & Lớp',
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
                    _loadKhoiList();
                    _loadLopList();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedTruong == null)
            const Center(
              child: Text(
                'Vui lòng thêm trường trước khi quản lý khối lớp',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Khối Học', icon: Icon(Icons.school)),
                      Tab(text: 'Lớp Học', icon: Icon(Icons.class_)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildKhoiTab(), _buildLopTab()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKhoiTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh Sách Khối',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showKhoiFormDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Khối'),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _khoiList.isEmpty
                  ? const Center(
                    child: Text(
                      'Chưa có khối nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                  : Card(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Tên Khối')),
                        DataColumn(label: Text('Mã Khối')),
                        DataColumn(label: Text('Ghi Chú')),
                        DataColumn(label: Text('Thao Tác')),
                      ],
                      rows:
                          _khoiList.map((khoi) {
                            return DataRow(
                              cells: [
                                DataCell(Text(khoi.tenKhoi)),
                                DataCell(Text(khoi.maKhoi)),
                                DataCell(Text(khoi.ghiChu ?? '')),
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
                                                _showKhoiFormDialog(khoi: khoi),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteKhoi(khoi),
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

  Widget _buildLopTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh Sách Lớp',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showLopFormDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Lớp'),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _lopList.isEmpty
                  ? const Center(
                    child: Text(
                      'Chưa có lớp nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                  : Card(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Tên Lớp')),
                        DataColumn(label: Text('Mã Lớp')),
                        DataColumn(label: Text('Sĩ Số')),
                        DataColumn(label: Text('Phòng Số')),
                        DataColumn(label: Text('Thao Tác')),
                      ],
                      rows:
                          _lopList.map((lop) {
                            return DataRow(
                              cells: [
                                DataCell(Text(lop.tenLop)),
                                DataCell(Text(lop.maLop)),
                                DataCell(Text(lop.siSo.toString())),
                                DataCell(Text(lop.phongSo)),
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
                                            () => _showLopFormDialog(lop: lop),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteLop(lop),
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

  void _showKhoiFormDialog({Khoi? khoi}) {
    showDialog(
      context: context,
      builder:
          (context) => KhoiFormDialog(
            truong: _selectedTruong!,
            khoi: khoi,
            onSaved: () {
              _loadKhoiList();
            },
          ),
    );
  }

  void _showLopFormDialog({Lop? lop}) {
    showDialog(
      context: context,
      builder:
          (context) => LopFormDialog(
            truong: _selectedTruong!,
            khoiList: _khoiList,
            lop: lop,
            onSaved: () {
              _loadLopList();
            },
          ),
    );
  }

  void _deleteKhoi(Khoi khoi) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác Nhận Xóa'),
            content: Text('Bạn có chắc chắn muốn xóa khối "${khoi.tenKhoi}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await KhoiService.deleteKhoi(khoi.id!);
                    _loadKhoiList();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Xóa khối thành công')),
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

  void _deleteLop(Lop lop) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác Nhận Xóa'),
            content: Text('Bạn có chắc chắn muốn xóa lớp "${lop.tenLop}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await LopService.deleteLop(lop.id!);
                    _loadLopList();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Xóa lớp thành công')),
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
