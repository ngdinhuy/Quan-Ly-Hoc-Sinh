import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diem_danh.dart';
import '../models/lop.dart';
import '../models/hoc_sinh.dart';
import '../services/diem_danh_service.dart';
import '../services/lop_service.dart';
import '../services/hoc_sinh_service.dart';

class QuanLyDiemDanhScreen extends StatefulWidget {
  const QuanLyDiemDanhScreen({super.key});

  @override
  State<QuanLyDiemDanhScreen> createState() => _QuanLyDiemDanhScreenState();
}

class _QuanLyDiemDanhScreenState extends State<QuanLyDiemDanhScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  List<Lop> _classes = [];
  Lop? _selectedClass;
  bool _isLoading = true;
  List<_AttendanceRecord> _records = [];
  final Map<String, HocSinh> _studentCache = {};

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
    setState(() => _isLoading = true);
    try {
      final classes = await LopService.getAllLop();
      setState(() {
        _classes = classes;
        if (classes.isNotEmpty && _selectedClass == null) {
          _selectedClass = classes.first;
        }
      });
      await _loadAttendanceRecords();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAttendanceRecords() async {
    if (_selectedClass == null) return;

    setState(() => _isLoading = true);
    try {
      final diemDanhRecords = await DiemDanhService.getByClass(
        _selectedClass!.id!,
        _selectedDate,
      );

      // Load student info for each record
      final records = <_AttendanceRecord>[];
      for (final record in diemDanhRecords) {
        HocSinh? student;
        if (_studentCache.containsKey(record.idHocSinh)) {
          student = _studentCache[record.idHocSinh];
        } else {
          student = await HocSinhService.getHocSinhById(record.idHocSinh);
          if (student != null) {
            _studentCache[record.idHocSinh] = student;
          }
        }
        records.add(_AttendanceRecord(
          diemDanh: record,
          student: student,
        ));
      }

      setState(() {
        _records = records;
      });
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải điểm danh: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadAttendanceRecords();
    }
  }

  Future<void> _deleteRecord(DiemDanh record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bản ghi điểm danh này? Hành động này không thể hoàn tác.',
        ),
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

    if (confirmed == true && record.id != null) {
      try {
        await DiemDanhService.delete(record.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa bản ghi thành công')),
          );
          await _loadAttendanceRecords();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa bản ghi: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteMultipleRecords(List<DiemDanh> records) async {
    if (records.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${records.length} bản ghi điểm danh? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        int successCount = 0;
        for (final record in records) {
          if (record.id != null) {
            await DiemDanhService.delete(record.id!);
            successCount++;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xóa $successCount bản ghi thành công')),
          );
          await _loadAttendanceRecords();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa bản ghi: $e')),
          );
        }
      }
    }
  }

  List<_AttendanceRecord> _getRecordsByStatus(TrangThaiDiemDanh status) {
    return _records.where((r) => r.diemDanh.trangThai == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản Lý Điểm Danh',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Class filter
                  const Text('Lớp: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<Lop?>(
                    value: _selectedClass,
                    hint: const Text('Chọn lớp'),
                    items: _classes.map((lop) {
                      return DropdownMenuItem(
                        value: lop,
                        child: Text(lop.tenLop),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClass = value;
                      });
                      _loadAttendanceRecords();
                    },
                  ),
                  const SizedBox(width: 24),
                  // Date picker
                  const Text('Ngày: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  ),
                  const Spacer(),
                  // Refresh button
                  IconButton(
                    onPressed: _loadAttendanceRecords,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Làm mới',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Summary cards
          Row(
            children: [
              _buildSummaryCard(
                'Tổng số',
                '${_records.length}',
                Icons.fact_check,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Đúng giờ',
                '${_getRecordsByStatus(TrangThaiDiemDanh.dungGio).length}',
                Icons.check_circle,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Đi muộn',
                '${_getRecordsByStatus(TrangThaiDiemDanh.tre).length}',
                Icons.schedule,
                Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Vắng phép',
                '${_getRecordsByStatus(TrangThaiDiemDanh.vangPhep).length}',
                Icons.event_busy,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tabs
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      text:
                          'Đúng giờ (${_getRecordsByStatus(TrangThaiDiemDanh.dungGio).length})',
                      icon: const Icon(Icons.check_circle),
                    ),
                    Tab(
                      text:
                          'Đi muộn (${_getRecordsByStatus(TrangThaiDiemDanh.tre).length})',
                      icon: const Icon(Icons.schedule),
                    ),
                    Tab(
                      text:
                          'Vắng phép (${_getRecordsByStatus(TrangThaiDiemDanh.vangPhep).length})',
                      icon: const Icon(Icons.event_busy),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecordsList(TrangThaiDiemDanh.dungGio),
                      _buildRecordsList(TrangThaiDiemDanh.tre),
                      _buildRecordsList(TrangThaiDiemDanh.vangPhep),
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

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Widget _buildRecordsList(TrangThaiDiemDanh status) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final records = _getRecordsByStatus(status);

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == TrangThaiDiemDanh.dungGio
                  ? Icons.check_circle_outline
                  : status == TrangThaiDiemDanh.tre
                      ? Icons.schedule
                      : Icons.event_busy,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có bản ghi ${status == TrangThaiDiemDanh.dungGio ? "đúng giờ" : status == TrangThaiDiemDanh.tre ? "đi muộn" : "vắng phép"}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          // Action bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${records.length} bản ghi',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (records.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _deleteMultipleRecords(
                      records.map((r) => r.diemDanh).toList(),
                    ),
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    label: const Text(
                      'Xóa tất cả',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Data table
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('STT')),
                  DataColumn(label: Text('Họ tên')),
                  DataColumn(label: Text('Số thẻ')),
                  DataColumn(label: Text('Ca')),
                  DataColumn(label: Text('Giờ check-in')),
                  DataColumn(label: Text('Phương thức')),
                  DataColumn(label: Text('Hành động')),
                ],
                rows: records.asMap().entries.map((entry) {
                  final index = entry.key;
                  final record = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(record.student?.hoTen ?? 'Không xác định')),
                      DataCell(Text(record.student?.soTheHocSinh ?? '-')),
                      DataCell(Text(record.diemDanh.caDisplayName)),
                      DataCell(Text(DateFormat('HH:mm')
                          .format(record.diemDanh.thoiGianCheckin))),
                      DataCell(Text(record.diemDanh.phuongThucDisplayName)),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRecord(record.diemDanh),
                          tooltip: 'Xóa bản ghi',
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRecord {
  final DiemDanh diemDanh;
  final HocSinh? student;

  _AttendanceRecord({
    required this.diemDanh,
    this.student,
  });
}
