import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/diem_danh.dart';
import '../../../models/hoc_sinh.dart';
import '../../../services/diem_danh_service.dart';
import '../../../services/phu_huynh_service.dart';
import '../../../services/hoc_sinh_service.dart';
import '../../../services/local_data_service.dart';

class LichSuVangMatScreen extends StatefulWidget {
  const LichSuVangMatScreen({super.key});

  @override
  State<LichSuVangMatScreen> createState() => _LichSuVangMatScreenState();
}

class _LichSuVangMatScreenState extends State<LichSuVangMatScreen> {
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  HocSinh? _hocSinh;
  List<Map<String, dynamic>> _absences = [];
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

      await _loadAbsences();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAbsences() async {
    if (_hocSinh == null) return;

    setState(() => _isLoading = true);

    try {
      final absences = await DiemDanhService.getAbsencesByStudent(
        _hocSinh!.id!,
        _startDate,
        _endDate,
      );

      // Sort by date descending
      absences.sort((a, b) {
        final dateA = a['date'] as DateTime;
        final dateB = b['date'] as DateTime;
        return dateB.compareTo(dateA);
      });

      setState(() => _absences = absences);
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
      await _loadAbsences();
    }
  }

  String _getCaDisplayName(CaDiemDanh ca) {
    switch (ca) {
      case CaDiemDanh.sang:
        return 'Ca Sáng';
      case CaDiemDanh.trua:
        return 'Ca Trưa';
      case CaDiemDanh.chieuToi:
        return 'Ca Chiều Tối';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Vắng Mặt'),
        backgroundColor: Colors.red,
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
                      : _buildAbsencesList(),
                ),
              ],
            ),
    );
  }

  Widget _buildStudentInfo() {
    if (_hocSinh == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.shade200,
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

  Widget _buildAbsencesList() {
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

    if (_absences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text(
              'Không có lịch sử vắng mặt',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Con bạn đã điểm danh đầy đủ trong khoảng thời gian này',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAbsences,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _absences.length,
        itemBuilder: (context, index) {
          final absence = _absences[index];
          return _buildAbsenceCard(absence);
        },
      ),
    );
  }

  Widget _buildAbsenceCard(Map<String, dynamic> absence) {
    final date = absence['date'] as DateTime;
    final ca = absence['ca'] as CaDiemDanh;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: const Icon(Icons.event_busy, color: Colors.red),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy').format(date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Vắng: ${_getCaDisplayName(ca)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Vắng mặt',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
