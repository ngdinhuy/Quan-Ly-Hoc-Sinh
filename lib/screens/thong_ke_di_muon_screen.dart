import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diem_danh.dart';
import '../models/lop.dart';
import '../services/diem_danh_service.dart';
import '../services/lop_service.dart';
import '../services/hoc_sinh_service.dart';

class ThongKeDiMuonScreen extends StatefulWidget {
  const ThongKeDiMuonScreen({super.key});

  @override
  State<ThongKeDiMuonScreen> createState() => _ThongKeDiMuonScreenState();
}

class _ThongKeDiMuonScreenState extends State<ThongKeDiMuonScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Lop> _classes = [];
  Lop? _selectedClass;
  bool _isLoading = true;
  List<_ClassAttendanceStats> _stats = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final classes = await LopService.getAllLop();
      setState(() {
        _classes = classes;
      });
      await _loadStatistics();
    } catch (e) {
      if (mounted) {
        debugPrint('huynd: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = <_ClassAttendanceStats>[];

      // Lấy ra danh sách học sinh thực hiện điểm danh theo ngày (chứa thông tin cả 3 ca sáng trưa tối)
      final lateRecords = await DiemDanhService.getLateByDate(_selectedDate);

      // Lấy ra lớp cần xem thông tin
      final classesToProcess =
          _selectedClass != null ? [_selectedClass!] : _classes;

      for (final lop in classesToProcess) {
        final students = await HocSinhService.getHocSinhByLop(lop.id!);
        final classLateRecords =
            lateRecords.where((r) => r.idLop == lop.id).toList();

        // Thực hiện lọc trùng từ danh sách điểm danh để ra danh sách học sinh đi muộn
        final lateStudentIds = <String>{};
        for (final record in classLateRecords) {
          lateStudentIds.add(record.idHocSinh);
        }

        // Get absence statistics
        final absenceStats = await DiemDanhService.getAbsenceStatistics(
          lop.id!,
          _selectedDate,
        );
        final absentStudentIds = (absenceStats['all_absent_ids'] as List<String>?) ?? [];

        stats.add(_ClassAttendanceStats(
          lop: lop,
          totalStudents: students.length,
          lateCount: classLateRecords.length,
          lateStudents: lateStudentIds.length,
          lateRecords: classLateRecords,
          absentCount: absentStudentIds.length,
          absentStudentIds: absentStudentIds,
        ));
      }

      setState(() {
        _stats = stats;
      });
    } catch (e) {
      if (mounted) {
        debugPrint("huynd:  ${e}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thống kê: $e')),
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
      await _loadStatistics();
    }
  }

  void _showStudentDetails(_ClassAttendanceStats stats) {
    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          title: Text('Chi tiết điểm danh - ${stats.lop.tenLop}'),
          content: SizedBox(
            width: 500,
            height: 450,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.blue,
                  tabs: [
                    Tab(text: 'Đi muộn'),
                    Tab(text: 'Vắng mặt'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Late students tab
                      _buildLateStudentsList(stats),
                      // Absent students tab
                      _buildAbsentStudentsList(stats),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLateStudentsList(_ClassAttendanceStats stats) {
    if (stats.lateRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green),
            SizedBox(height: 8),
            Text('Không có học sinh đi muộn'),
          ],
        ),
      );
    }

    return FutureBuilder<List<_StudentInfo>>(
      future: _getLateStudentInfo(stats.lateRecords),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final infos = snapshot.data ?? [];
        return ListView.builder(
          itemCount: infos.length,
          itemBuilder: (context, index) {
            final info = infos[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Text('${index + 1}'),
              ),
              title: Text(info.studentName),
              subtitle: Text(
                '${info.record!.caDisplayName} - Check-in: ${DateFormat('HH:mm').format(info.record!.thoiGianCheckin)}',
              ),
              trailing: const Icon(Icons.schedule, color: Colors.orange),
            );
          },
        );
      },
    );
  }

  Widget _buildAbsentStudentsList(_ClassAttendanceStats stats) {
    if (stats.absentStudentIds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green),
            SizedBox(height: 8),
            Text('Không có học sinh vắng mặt'),
          ],
        ),
      );
    }

    return FutureBuilder<List<_StudentInfo>>(
      future: _getAbsentStudentInfo(stats.absentStudentIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final infos = snapshot.data ?? [];
        return ListView.builder(
          itemCount: infos.length,
          itemBuilder: (context, index) {
            final info = infos[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade100,
                child: Text('${index + 1}'),
              ),
              title: Text(info.studentName),
              subtitle: const Text('Chưa điểm danh'),
              trailing: const Icon(Icons.event_busy, color: Colors.red),
            );
          },
        );
      },
    );
  }

  Future<List<_StudentInfo>> _getLateStudentInfo(List<DiemDanh> records) async {
    final infos = <_StudentInfo>[];
    for (final record in records) {
      final student = await HocSinhService.getHocSinhById(record.idHocSinh);
      infos.add(_StudentInfo(
        studentId: record.idHocSinh,
        studentName: student?.hoTen ?? 'Unknown',
        record: record,
      ));
    }
    return infos;
  }

  Future<List<_StudentInfo>> _getAbsentStudentInfo(List<String> studentIds) async {
    final infos = <_StudentInfo>[];
    for (final id in studentIds) {
      final student = await HocSinhService.getHocSinhById(id);
      infos.add(_StudentInfo(
        studentId: id,
        studentName: student?.hoTen ?? 'Unknown',
      ));
    }
    return infos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Date picker
                    const Text('Ngày: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    ),
                    const SizedBox(width: 24),
                    // Class filter
                    const Text('Lớp: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<Lop?>(
                      value: _selectedClass,
                      hint: const Text('Tất cả'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tất cả')),
                        ..._classes.map((lop) {
                          return DropdownMenuItem(
                            value: lop,
                            child: Text(lop.tenLop),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedClass = value;
                        });
                        _loadStatistics();
                      },
                    ),
                    const Spacer(),
                    // Refresh button
                    IconButton(
                      onPressed: _loadStatistics,
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
                  'Tổng lớp',
                  '${_stats.length}',
                  Icons.class_,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  'Đi muộn',
                  '${_stats.fold(0, (sum, s) => sum + s.lateStudents)}',
                  Icons.schedule,
                  Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  'Vắng mặt',
                  '${_stats.fold(0, (sum, s) => sum + s.absentCount)}',
                  Icons.event_busy,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Lớp')),
                            DataColumn(label: Text('Tổng HS'), numeric: true),
                            DataColumn(label: Text('Đi muộn'), numeric: true),
                            DataColumn(label: Text('Vắng mặt'), numeric: true),
                            DataColumn(label: Text('Tỷ lệ vắng')),
                            DataColumn(label: Text('Chi tiết')),
                          ],
                          rows: _stats.map((stat) {
                            final absentPercentage = stat.totalStudents > 0
                                ? (stat.absentCount / stat.totalStudents * 100)
                                    .toStringAsFixed(1)
                                : '0';
                            return DataRow(
                              cells: [
                                DataCell(Text(stat.lop.tenLop)),
                                DataCell(Text('${stat.totalStudents}')),
                                DataCell(
                                  Text(
                                    '${stat.lateStudents}',
                                    style: TextStyle(
                                      color: stat.lateStudents > 0 ? Colors.orange : null,
                                      fontWeight: stat.lateStudents > 0 ? FontWeight.bold : null,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${stat.absentCount}',
                                    style: TextStyle(
                                      color: stat.absentCount > 0 ? Colors.red : null,
                                      fontWeight: stat.absentCount > 0 ? FontWeight.bold : null,
                                    ),
                                  ),
                                ),
                                DataCell(Text('$absentPercentage%')),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: (stat.lateCount > 0 || stat.absentCount > 0)
                                        ? () => _showStudentDetails(stat)
                                        : null,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
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
}

class _ClassAttendanceStats {
  final Lop lop;
  final int totalStudents;
  final int lateCount;
  final int lateStudents;
  final List<DiemDanh> lateRecords;
  final int absentCount;
  final List<String> absentStudentIds;

  _ClassAttendanceStats({
    required this.lop,
    required this.totalStudents,
    required this.lateCount,
    required this.lateStudents,
    required this.lateRecords,
    required this.absentCount,
    required this.absentStudentIds,
  });
}

class _StudentInfo {
  final String studentId;
  final String studentName;
  final DiemDanh? record;

  _StudentInfo({
    required this.studentId,
    required this.studentName,
    this.record,
  });
}
