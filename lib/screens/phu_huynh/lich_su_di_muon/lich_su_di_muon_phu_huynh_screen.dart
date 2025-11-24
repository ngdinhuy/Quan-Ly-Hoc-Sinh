import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/diem_danh.dart';
import '../../../models/hoc_sinh.dart';
import '../../../services/diem_danh_service.dart';
import '../../../services/phu_huynh_service.dart';
import '../../../services/hoc_sinh_service.dart';
import '../../../services/local_data_service.dart';

class LichSuDiMuonPhuHuynhScreen extends StatefulWidget {
  const LichSuDiMuonPhuHuynhScreen({super.key});

  @override
  State<LichSuDiMuonPhuHuynhScreen> createState() => _LichSuDiMuonPhuHuynhScreenState();
}

class _LichSuDiMuonPhuHuynhScreenState extends State<LichSuDiMuonPhuHuynhScreen> {
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  HocSinh? _hocSinh;
  List<DiemDanh> _lateRecords = [];
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
      final parentId = LocalDataService.instance.getId();
      if (parentId == null) {
        throw Exception('Không tìm thấy thông tin phụ huynh');
      }

      // Get parent info
      final phuHuynh = await PhuHuynhService.getPhuHuynhById(parentId);
      if (phuHuynh == null) {
        throw Exception('Không tìm thấy thông tin phụ huynh');
      }

      // Get linked student
      final hocSinh = await HocSinhService.getHocSinhById(phuHuynh.idHs);
      if (hocSinh == null) {
        throw Exception('Không tìm thấy thông tin học sinh');
      }

      setState(() {
        _hocSinh = hocSinh;
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
    if (_hocSinh == null) return;

    setState(() => _isLoading = true);

    try {
      final records = await DiemDanhService.getLateByStudent(
        _hocSinh!.id!,
        _startDate,
        _endDate,
      );

      // Sort by date descending
      records.sort((a, b) => b.ngay.compareTo(a.ngay));

      setState(() => _lateRecords = records);
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
        backgroundColor: Colors.orange,
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
                _buildStudentInfo(),
                _buildDateFilter(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildRecordsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildStudentInfo() {
    if (_hocSinh == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade200,
              backgroundImage: _hocSinh?.avatarFaceUrl != null
                  ? NetworkImage(_hocSinh!.avatarFaceUrl!)
                  : null,
              child: _hocSinh?.avatarFaceUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hocSinh!.hoTen,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Lớp: ${_hocSinh!.phongSo}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'Từ ngày:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    if (_hocSinh == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Không có học sinh liên kết'),
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
            Text('Không có lịch sử đi muộn trong khoảng thời gian này'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLateRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lateRecords.length,
        itemBuilder: (context, index) {
          final record = _lateRecords[index];
          return _buildRecordCard(record);
        },
      ),
    );
  }

  Widget _buildRecordCard(DiemDanh record) {
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
          DateFormat('dd/MM/yyyy').format(record.ngay),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Ca: ${record.caDisplayName} - Check-in: ${DateFormat('HH:mm').format(record.thoiGianCheckin)}',
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
      ),
    );
  }
}
