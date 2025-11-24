import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/download_helper.dart' as download_helper;

import '../models/lop.dart';
import '../services/lop_service.dart';
import '../services/thong_ke_xuat_an_service.dart';

/// Admin screen for viewing meal statistics by class and date
class ThongKeXuatAnScreen extends StatefulWidget {
  const ThongKeXuatAnScreen({super.key});

  @override
  State<ThongKeXuatAnScreen> createState() => _ThongKeXuatAnScreenState();
}

class _ThongKeXuatAnScreenState extends State<ThongKeXuatAnScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Daily view state
  DateTime _selectedDate = DateTime.now();
  List<MealStatistics> _dailyStatistics = [];
  bool _isDailyLoading = false;

  // Monthly view state
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  Map<DateTime, int> _monthlyOverview = {};
  bool _isMonthlyLoading = false;

  // Filter
  List<Lop> _lopList = [];
  Lop? _selectedLop;

  // Export
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClasses();
    _loadDailyStatistics();
    _loadMonthlyStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await LopService.getAllLop();
      if (mounted) {
        setState(() {
          _lopList = classes;
        });
      }
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  Future<void> _loadDailyStatistics() async {
    setState(() => _isDailyLoading = true);

    try {
      List<MealStatistics> stats;
      if (_selectedLop != null) {
        final stat = await ThongKeXuatAnService.getStatisticsByClassAndDate(
          _selectedLop!.id!,
          _selectedDate,
        );
        stats = stat != null ? [stat] : [];
      } else {
        stats = await ThongKeXuatAnService.getStatisticsByDate(_selectedDate);
      }

      if (mounted) {
        setState(() {
          _dailyStatistics = stats;
          _isDailyLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading daily statistics: $e');
      if (mounted) {
        setState(() => _isDailyLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  Future<void> _loadMonthlyStatistics() async {
    setState(() => _isMonthlyLoading = true);

    try {
      final overview = await ThongKeXuatAnService.getMonthlyOverview(
        _selectedYear,
        _selectedMonth,
      );

      if (mounted) {
        setState(() {
          _monthlyOverview = overview;
          _isMonthlyLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading monthly statistics: $e');
      if (mounted) {
        setState(() => _isMonthlyLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadDailyStatistics();
    }
  }

  Future<void> _selectMonth() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        initialYear: _selectedYear,
        initialMonth: _selectedMonth,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedYear = picked.year;
        _selectedMonth = picked.month;
      });
      _loadMonthlyStatistics();
    }
  }

  Future<void> _exportDailyToExcel() async {
    if (_dailyStatistics.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không có dữ liệu để xuất')));
      return;
    }

    setState(() => _isExporting = true);

    try {
      final bytes = await ThongKeXuatAnService.exportDailyToExcel(
        _selectedDate,
        _dailyStatistics,
      );

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final fileName = 'thong_ke_xuat_an_$dateStr.xlsx';

      _downloadFile(bytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã xuất file: $fileName')));
      }
    } catch (e) {
      debugPrint('Error exporting: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xuất file: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportMonthlyToExcel() async {
    if (_monthlyOverview.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không có dữ liệu để xuất')));
      return;
    }

    setState(() => _isExporting = true);

    try {
      final bytes = await ThongKeXuatAnService.exportMonthlyToExcel(
        _selectedYear,
        _selectedMonth,
        _monthlyOverview,
        _lopList,
      );

      final monthStr =
          '${_selectedMonth.toString().padLeft(2, '0')}-$_selectedYear';
      final fileName = 'thong_ke_xuat_an_thang_$monthStr.xlsx';

      _downloadFile(bytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã xuất file: $fileName')));
      }
    } catch (e) {
      debugPrint('Error exporting: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xuất file: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _downloadFile(List<int> bytes, String fileName) {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tính năng này chỉ hỗ trợ trên web')),
      );
      return;
    }
    download_helper.downloadFile(bytes, fileName);
  }

  void _navigateToDailyView(DateTime date) {
    setState(() {
      _selectedDate = date;
      _tabController.animateTo(0);
    });
    _loadDailyStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống Kê Xuất Ăn'),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Theo ngày'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Theo tháng'),
          ],
        ),
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Xuất Excel',
              onPressed: () {
                if (_tabController.index == 0) {
                  _exportDailyToExcel();
                } else {
                  _exportMonthlyToExcel();
                }
              },
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDailyView(), _buildMonthlyView()],
      ),
    );
  }

  Widget _buildDailyView() {
    return Column(
      children: [
        // Filter row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date picker
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.orange),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: Colors.orange),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Class filter
              Expanded(
                child: DropdownButtonFormField<Lop?>(
                  initialValue: _selectedLop,
                  decoration: InputDecoration(
                    labelText: 'Lọc theo lớp',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<Lop?>(
                      value: null,
                      child: Text('Tất cả lớp'),
                    ),
                    ..._lopList.map(
                      (lop) => DropdownMenuItem<Lop?>(
                        value: lop,
                        child: Text(lop.tenLop),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedLop = value);
                    _loadDailyStatistics();
                  },
                ),
              ),
            ],
          ),
        ),

        // Statistics table
        Expanded(
          child: _isDailyLoading
              ? const Center(child: CircularProgressIndicator())
              : _dailyStatistics.isEmpty
              ? const Center(
                  child: Text(
                    'Không có dữ liệu',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : _buildDailyTable(),
        ),
      ],
    );
  }

  Widget _buildDailyTable() {
    // Calculate totals
    int totalStudents = 0;
    int totalDeductions = 0;
    int totalEating = 0;

    for (final stat in _dailyStatistics) {
      totalStudents += stat.tongHocSinh;
      totalDeductions += stat.soCatCom;
      totalEating += stat.soAnCom;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Lớp')),
              DataColumn(label: Text('Tổng HS'), numeric: true),
              DataColumn(label: Text('Cắt cơm'), numeric: true),
              DataColumn(label: Text('Ăn cơm'), numeric: true),
            ],
            rows: [
              ..._dailyStatistics.map(
                (stat) => DataRow(
                  cells: [
                    DataCell(Text(stat.tenLop)),
                    DataCell(Text(stat.tongHocSinh.toString())),
                    DataCell(
                      Text(
                        stat.soCatCom.toString(),
                        style: TextStyle(
                          color: stat.soCatCom > 0 ? Colors.red : null,
                          fontWeight: stat.soCatCom > 0
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        stat.soAnCom.toString(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Summary row
              DataRow(
                color: WidgetStateProperty.all(Colors.orange.withAlpha(50)),
                cells: [
                  const DataCell(
                    Text(
                      'TỔNG CỘNG',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      totalStudents.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      totalDeductions.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      totalEating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
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

  Widget _buildMonthlyView() {
    return Column(
      children: [
        // Month picker row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectMonth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.orange),
                        const SizedBox(width: 12),
                        Text(
                          'Tháng $_selectedMonth/$_selectedYear',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: Colors.orange),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Monthly statistics
        Expanded(
          child: _isMonthlyLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildMonthlyTable(),
        ),
      ],
    );
  }

  Widget _buildMonthlyTable() {
    // Generate all days in the month
    final startDate = DateTime(_selectedYear, _selectedMonth, 1);
    final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final days = <DateTime>[];

    DateTime current = startDate;
    while (!current.isAfter(endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    // Calculate totals
    int totalDeductions = 0;
    for (final entry in _monthlyOverview.entries) {
      totalDeductions += entry.value;
    }
    final average = days.isNotEmpty ? totalDeductions / days.length : 0.0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Summary cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Tổng cắt cơm trong tháng',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            totalDeductions.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Trung bình/ngày',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            average.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Daily table
            Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Ngày')),
                  DataColumn(label: Text('Thứ')),
                  DataColumn(label: Text('Cắt cơm'), numeric: true),
                  DataColumn(label: Text('Xem')),
                ],
                rows: days.map((day) {
                  final deductions = _monthlyOverview[day] ?? 0;
                  final dayOfWeek = _getDayOfWeekVi(day.weekday);

                  return DataRow(
                    cells: [
                      DataCell(Text(DateFormat('dd/MM').format(day))),
                      DataCell(Text(dayOfWeek)),
                      DataCell(
                        Text(
                          deductions.toString(),
                          style: TextStyle(
                            color: deductions > 0 ? Colors.red : Colors.grey,
                            fontWeight: deductions > 0 ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.blue,
                            size: 20,
                          ),
                          onPressed: () => _navigateToDailyView(day),
                          tooltip: 'Xem chi tiết',
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayOfWeekVi(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }
}

/// Dialog for picking month and year
class _MonthYearPickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;

  const _MonthYearPickerDialog({
    required this.initialYear,
    required this.initialMonth,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _month = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn tháng'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _year--),
              ),
              Text(
                _year.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _year++),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Month grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (index) {
              final month = index + 1;
              final isSelected = month == _month;
              return InkWell(
                onTap: () => setState(() => _month = month),
                child: Container(
                  width: 60,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'T$month',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, DateTime(_year, _month)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Chọn'),
        ),
      ],
    );
  }
}
