import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../models/lop.dart';
import 'hoc_sinh_service.dart';
import 'lop_service.dart';
import 'xin_ve_phep_service.dart';

/// Model for meal statistics per class
class MealStatistics {
  final String idLop;
  final String tenLop;
  final int tongHocSinh;
  final int soCatCom;

  MealStatistics({
    required this.idLop,
    required this.tenLop,
    required this.tongHocSinh,
    required this.soCatCom,
  });

  int get soAnCom => tongHocSinh - soCatCom;
}

/// Service for meal statistics calculations and export
class ThongKeXuatAnService {
  /// Get meal statistics for all classes on a specific date
  static Future<List<MealStatistics>> getStatisticsByDate(DateTime date) async {
    // Get all classes
    final classes = await LopService.getAllLop();

    // Get all approved leave permissions with meal deduction on this date
    final approvedLeaves = await XinVePhepService.getApprovedByMealDate(date);

    // Group meal deductions by class (count distinct students)
    final Map<String, Set<String>> deductionsByClass = {};
    for (final leave in approvedLeaves) {
      deductionsByClass.putIfAbsent(leave.idLop, () => {});
      deductionsByClass[leave.idLop]!.add(leave.idHocSinh);
    }

    // Calculate statistics for each class
    List<MealStatistics> statistics = [];

    for (final lop in classes) {
      // Get total students in this class
      final students = await HocSinhService.getHocSinhByLop(lop.id!);
      final totalStudents = students.length;

      // Get meal deductions for this class (distinct students)
      final deductions = deductionsByClass[lop.id]?.length ?? 0;

      statistics.add(
        MealStatistics(
          idLop: lop.id!,
          tenLop: lop.tenLop,
          tongHocSinh: totalStudents,
          soCatCom: deductions,
        ),
      );
    }

    // Sort by class name
    statistics.sort((a, b) => a.tenLop.compareTo(b.tenLop));

    return statistics;
  }

  /// Get meal statistics for a specific class on a specific date
  static Future<MealStatistics?> getStatisticsByClassAndDate(
    String idLop,
    DateTime date,
  ) async {
    final lop = await LopService.getLopById(idLop);
    if (lop == null) return null;

    // Get total students
    final students = await HocSinhService.getHocSinhByLop(idLop);
    final totalStudents = students.length;

    // Get approved leave permissions with meal deduction on this date
    final approvedLeaves = await XinVePhepService.getApprovedByMealDate(date);

    // Count distinct students with meal deduction in this class
    final distinctStudents = approvedLeaves
        .where((leave) => leave.idLop == idLop)
        .map((leave) => leave.idHocSinh)
        .toSet();

    return MealStatistics(
      idLop: idLop,
      tenLop: lop.tenLop,
      tongHocSinh: totalStudents,
      soCatCom: distinctStudents.length,
    );
  }

  /// Get monthly overview: map of date -> total meal deductions across all classes
  static Future<Map<DateTime, int>> getMonthlyOverview(
    int year,
    int month,
  ) async {
    // Calculate date range for the month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month

    // Get all approved leave permissions in this date range
    final approvedLeaves = await XinVePhepService.getApprovedInDateRange(
      startDate,
      endDate,
    );

    // Count meal deductions per day (distinct students per day)
    final Map<DateTime, Set<String>> deductionsByDay = {};

    for (final leave in approvedLeaves) {
      for (final mealDate in leave.danhSachNgayCatCom) {
        final dateOnly = DateTime(mealDate.year, mealDate.month, mealDate.day);

        // Only count dates within the month
        if (dateOnly.year == year && dateOnly.month == month) {
          deductionsByDay.putIfAbsent(dateOnly, () => {});
          deductionsByDay[dateOnly]!.add(leave.idHocSinh);
        }
      }
    }

    // Convert to count map
    final Map<DateTime, int> result = {};
    for (final entry in deductionsByDay.entries) {
      result[entry.key] = entry.value.length;
    }

    return result;
  }

  /// Get detailed monthly statistics: map of date -> list of statistics per class
  static Future<Map<DateTime, List<MealStatistics>>> getMonthlyDetailedStats(
    int year,
    int month,
  ) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final Map<DateTime, List<MealStatistics>> result = {};

    // Iterate through each day of the month
    DateTime current = startDate;
    while (!current.isAfter(endDate)) {
      result[current] = await getStatisticsByDate(current);
      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  /// Export daily statistics to Excel
  static Future<Uint8List> exportDailyToExcel(
    DateTime date,
    List<MealStatistics> stats,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Thống kê xuất ăn'];

    // Remove default sheet
    excel.delete('Sheet1');

    // Date header
    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    sheet.appendRow([TextCellValue('Thống kê xuất ăn ngày $dateStr')]);
    sheet.appendRow([TextCellValue('')]); // Empty row

    // Header row
    sheet.appendRow([
      TextCellValue('Lớp'),
      TextCellValue('Tổng HS'),
      TextCellValue('Cắt cơm'),
      TextCellValue('Ăn cơm'),
    ]);

    // Data rows
    int totalStudents = 0;
    int totalDeductions = 0;
    int totalEating = 0;

    for (final stat in stats) {
      sheet.appendRow([
        TextCellValue(stat.tenLop),
        IntCellValue(stat.tongHocSinh),
        IntCellValue(stat.soCatCom),
        IntCellValue(stat.soAnCom),
      ]);

      totalStudents += stat.tongHocSinh;
      totalDeductions += stat.soCatCom;
      totalEating += stat.soAnCom;
    }

    // Summary row
    sheet.appendRow([TextCellValue('')]); // Empty row
    sheet.appendRow([
      TextCellValue('TỔNG CỘNG'),
      IntCellValue(totalStudents),
      IntCellValue(totalDeductions),
      IntCellValue(totalEating),
    ]);

    // Set column widths
    sheet.setColumnWidth(0, 20); // Lớp
    sheet.setColumnWidth(1, 12); // Tổng HS
    sheet.setColumnWidth(2, 12); // Cắt cơm
    sheet.setColumnWidth(3, 12); // Ăn cơm

    return Uint8List.fromList(excel.encode()!);
  }

  /// Export monthly overview to Excel
  static Future<Uint8List> exportMonthlyToExcel(
    int year,
    int month,
    Map<DateTime, int> data,
    List<Lop> classes,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Thống kê tháng'];

    // Remove default sheet
    excel.delete('Sheet1');

    // Month header
    final monthStr = '$month/$year';
    sheet.appendRow([TextCellValue('Thống kê xuất ăn tháng $monthStr')]);
    sheet.appendRow([TextCellValue('')]); // Empty row

    // Header row
    sheet.appendRow([TextCellValue('Ngày'), TextCellValue('Tổng cắt cơm')]);

    // Data rows - iterate through all days of the month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    int totalDeductions = 0;

    DateTime current = startDate;
    while (!current.isAfter(endDate)) {
      final deductions = data[current] ?? 0;
      sheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy').format(current)),
        IntCellValue(deductions),
      ]);
      totalDeductions += deductions;
      current = current.add(const Duration(days: 1));
    }

    // Summary row
    sheet.appendRow([TextCellValue('')]); // Empty row
    sheet.appendRow([
      TextCellValue('TỔNG CỘNG'),
      IntCellValue(totalDeductions),
    ]);

    final daysInMonth = endDate.day;
    final average = totalDeductions / daysInMonth;
    sheet.appendRow([
      TextCellValue('Trung bình/ngày'),
      DoubleCellValue(double.parse(average.toStringAsFixed(1))),
    ]);

    // Set column widths
    sheet.setColumnWidth(0, 15); // Ngày
    sheet.setColumnWidth(1, 15); // Tổng cắt cơm

    return Uint8List.fromList(excel.encode()!);
  }
}
