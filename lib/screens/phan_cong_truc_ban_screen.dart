import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/phan_cong_truc_ban.dart';
import '../models/truong.dart';
import '../models/giao_vien.dart';
import '../services/phan_cong_truc_ban_service.dart';
import '../services/truong_service.dart';
import '../services/giao_vien_service.dart';
import 'add_phan_cong_truc_ban_screen.dart';

class PhanCongTrucBanScreen extends StatefulWidget {
  const PhanCongTrucBanScreen({Key? key}) : super(key: key);

  @override
  State<PhanCongTrucBanScreen> createState() => _PhanCongTrucBanScreenState();
}

class _PhanCongTrucBanScreenState extends State<PhanCongTrucBanScreen> {
  bool _isLoading = true;
  List<PhanCongTrucBan> _danhSachTrucBan = [];
  List<Truong> _danhSachTruong = [];
  String? _selectedTruongId;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final Map<String, GiaoVien> _giaoVienCache = {};
  Map<String, Truong> _truongCache = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load schools
      final danhSachTruong = await TruongService.getAllTruong();

      // Create school cache
      Map<String, Truong> truongCache = {};
      for (var truong in danhSachTruong) {
        if (truong.id != null) {
          truongCache[truong.id!] = truong;
        }
      }

      // Load duty assignments
      List<PhanCongTrucBan> danhSachTrucBan;
      if (_selectedTruongId != null) {
        danhSachTrucBan = await PhanCongTrucBanService.getBySchoolId(_selectedTruongId!);
      } else {
        danhSachTrucBan = await PhanCongTrucBanService.getAll();
      }

      // Prefetch teacher data
      Set<String> giaoVienIds = danhSachTrucBan.map((e) => e.idGiaoVien).toSet();
      for (String id in giaoVienIds) {
        _loadGiaoVien(id);
      }

      setState(() {
        _danhSachTruong = danhSachTruong;
        _danhSachTrucBan = danhSachTrucBan;
        _truongCache = truongCache;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Đã xảy ra lỗi khi tải dữ liệu: ${e.toString()}');
    }
  }

  Future<void> _loadGiaoVien(String idGiaoVien) async {
    if (!_giaoVienCache.containsKey(idGiaoVien)) {
      try {
        final giaoVien = await GiaoVienService.getGiaoVienById(idGiaoVien);
        if (giaoVien != null && mounted) {
          setState(() {
            _giaoVienCache[idGiaoVien] = giaoVien;
          });
        }
      } catch (e) {
        print('Error loading teacher $idGiaoVien: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo trường'),
        content: SizedBox(
          width: double.maxFinite,
          child: _danhSachTruong.isEmpty
              ? const Text('Không có dữ liệu trường')
              : DropdownButtonFormField<String?>(
            value: _selectedTruongId,
            decoration: const InputDecoration(
              labelText: 'Chọn trường',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('-- Tất cả trường --'),
              ),
              ..._danhSachTruong.map(
                    (truong) => DropdownMenuItem<String?>(
                  value: truong.id,
                  child: Text(truong.tenTruong),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTruongId = value;
              });
              Navigator.pop(context);
              _loadData();
            },
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

  Future<void> _showAddEditDialog({PhanCongTrucBan? phanCong}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPhanCongTrucBanScreen(
          phanCong: phanCong,
          danhSachTruong: _danhSachTruong,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa phân công trực ban này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await PhanCongTrucBanService.delete(id);
        setState(() => _isLoading = false);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa phân công trực ban')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog('Không thể xóa: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân công trực ban'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Lọc theo trường',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_selectedTruongId != null)
            Container(
              color: Colors.blue.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đang lọc: ${_truongCache[_selectedTruongId]?.tenTruong ?? ""}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedTruongId = null;
                      });
                      _loadData();
                    },
                    tooltip: 'Xóa bộ lọc',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _danhSachTrucBan.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Không có dữ liệu phân công trực ban',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm mới'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _danhSachTrucBan.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final phanCong = _danhSachTrucBan[index];
                final giaoVien = _giaoVienCache[phanCong.idGiaoVien];
                final truong = _truongCache[phanCong.idTruong];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8
                    ),
                    title: Text(
                      giaoVien?.hoTen ?? 'Đang tải...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Trường: ${truong?.tenTruong ?? phanCong.idTruong}',
                          style: const TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ngày trực: ${_formatDateList(phanCong.ngayTrucBan)}',
                        ),
                        if (phanCong.ghiChu != null &&
                            phanCong.ghiChu!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ghi chú: ${phanCong.ghiChu}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddEditDialog(phanCong: phanCong),
                          tooltip: 'Chỉnh sửa',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(phanCong.id!),
                          tooltip: 'Xóa',
                        ),
                      ],
                    ),
                    onTap: () => _showAddEditDialog(phanCong: phanCong),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        tooltip: 'Thêm phân công trực ban',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDateList(List<DateTime> dates) {
    if (dates.isEmpty) return 'Không có';

    if (dates.length <= 3) {
      return dates.map((date) => _dateFormat.format(date)).join(', ');
    } else {
      return '${dates.length} ngày (${_dateFormat.format(dates.first)} - ${_dateFormat.format(dates.last)})';
    }
  }
}

