import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/diem_danh.dart';
import '../../../services/diem_danh_service.dart';
import '../../../services/hoc_sinh_service.dart';
import '../../../services/phan_cong_chu_nhiem_service.dart';
import '../../../services/local_data_service.dart';

class LichSuDiMuonScreen extends StatefulWidget {
  const LichSuDiMuonScreen({super.key});

  @override
  State<LichSuDiMuonScreen> createState() => _LichSuDiMuonScreenState();
}

class _LichSuDiMuonScreenState extends State<LichSuDiMuonScreen> {
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _homeroomClasses = [];
  String? _selectedClassId;
  List<_LateRecordWithStudent> _lateRecords = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teacherId = LocalDataService.instance.getId();
      if (teacherId == null) {
        throw Exception('Không tìm thấy thông tin giáo viên');
      }

      // Get homeroom classes for this teacher
      final classes = await PhanCongChuNhiemService.getClassesByTeacherId(teacherId);

      setState(() {
        _homeroomClasses = classes;
        if (classes.isNotEmpty && _selectedClassId == null) {
          _selectedClassId = classes.first['lop']['id'];
        }
      });

      await _loadLateRecords();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLateRecords() async {
    if (_selectedClassId == null) {
      setState(() => _lateRecords = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final records = await DiemDanhService.getLateByClass(
        _selectedClassId!,
        _startDate,
        _endDate,
      );

      // Enrich with student names
      final enrichedRecords = <_LateRecordWithStudent>[];
      for (final record in records) {
        final student = await HocSinhService.getHocSinhById(record.idHocSinh);
        enrichedRecords.add(_LateRecordWithStudent(
          record: record,
          studentName: student?.hoTen ?? 'Không xác định',
        ));
      }

      // Sort by date descending
      enrichedRecords.sort((a, b) => b.record.ngay.compareTo(a.record.ngay));

      setState(() => _lateRecords = enrichedRecords);
    } catch (e) {
      debugPrint('huynd: ${e}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadLateRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Đi Muộn'),
        backgroundColor: Colors.blue,
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildRecordsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    final List<DropdownMenuItem<String>> classItems = _homeroomClasses.map((classInfo) {
      final tenLop = (classInfo['lop']['ten_lop'] ?? 'Không tên') as String;
      final id = classInfo['lop']['id'] as String;
      return DropdownMenuItem<String>(
        value: id,
        child: Text(tenLop),
      );
    }).toList();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class selector
            if (_homeroomClasses.isNotEmpty) ...[
              const Text(
                'Lớp chủ nhiệm:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedClassId,
                isExpanded: true,
                items: classItems,
                onChanged: (value) {
                  setState(() => _selectedClassId = value);
                  _loadLateRecords();
                },
              ),
              const SizedBox(height: 16),
            ],
            // Date range picker
            Row(
              children: [
                const Text(
                  'Từ ngày:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    if (_homeroomClasses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Bạn không có lớp chủ nhiệm'),
          ],
        ),
      );
    }

    if (_lateRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Không có học sinh đi muộn trong khoảng thời gian này'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLateRecords,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _lateRecords.length,
        itemBuilder: (context, index) {
          final item = _lateRecords[index];
          return _buildRecordCard(item);
        },
      ),
    );
  }

  Widget _buildRecordCard(_LateRecordWithStudent item) {
    final record = item.record;
    final isExcused = record.trangThai == TrangThaiDiemDanh.vangPhep;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExcused ? Colors.blue.shade100 : Colors.orange.shade100,
          child: Icon(
            isExcused ? Icons.event_busy : Icons.schedule,
            color: isExcused ? Colors.blue : Colors.orange,
          ),
        ),
        title: Text(
          item.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ngày: ${DateFormat('dd/MM/yyyy').format(record.ngay)}',
            ),
            Text(
              'Ca: ${record.caDisplayName} - Check-in: ${DateFormat('HH:mm').format(record.thoiGianCheckin)}',
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isExcused ? Colors.blue.shade100 : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            record.trangThaiDisplayName,
            style: TextStyle(
              color: isExcused ? Colors.blue.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _LateRecordWithStudent {
  final DiemDanh record;
  final String studentName;

  _LateRecordWithStudent({required this.record, required this.studentName});
}
