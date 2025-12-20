import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/diem_danh.dart';
import '../models/lop.dart';
import 'firebase_service.dart';
import 'xin_ve_phep_service.dart';
import 'lop_service.dart';
import 'hoc_sinh_service.dart';

class DiemDanhService {
  static const String collection = 'diem_danh';

  /// Create a new attendance record
  static Future<String> create(DiemDanh diemDanh) async {
    final docRef = await FirebaseService.firestore
        .collection(collection)
        .add(diemDanh.toFirestore());
    return docRef.id;
  }

  /// Check in a student for attendance
  /// Returns the created DiemDanh record or null if already checked in
  static Future<DiemDanh?> checkIn({
    required String idHocSinh,
    required String idLop,
    required CaDiemDanh ca,
    required PhuongThucDiemDanh phuongThuc,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check for existing check-in
    final existing = await getByStudentAndDate(idHocSinh, today, ca);
    if (existing != null) {
      return null; // Already checked in
    }

    // Get class config for late calculation
    final lop = await LopService.getLopById(idLop);
    final config = lop?.getConfigForToday() ?? CaHocConfig.defaultConfig();

    // Calculate late status
    final trangThai = await calculateLateStatus(
      checkInTime: now,
      config: config,
      ca: ca,
      idHocSinh: idHocSinh,
      date: today,
    );

    final diemDanh = DiemDanh(
      idHocSinh: idHocSinh,
      idLop: idLop,
      ngay: today,
      ca: ca,
      thoiGianCheckin: now,
      phuongThuc: phuongThuc,
      trangThai: trangThai,
      createdAt: now,
    );

    final id = await create(diemDanh);
    return diemDanh.copyWith(id: id);
  }

  /// Calculate late status based on check-in time and config
  static Future<TrangThaiDiemDanh> calculateLateStatus({
    required DateTime checkInTime,
    required CaHocConfig config,
    required CaDiemDanh ca,
    required String idHocSinh,
    required DateTime date,
  }) async {
    // Check if student has approved leave for this date
    final isOnLeave = await checkIsOnLeave(idHocSinh, date);
    if (isOnLeave) {
      return TrangThaiDiemDanh.vangPhep;
    }

    // Get the end time for this period
    ThoiGianCa thoiGian;
    switch (ca) {
      case CaDiemDanh.sang:
        thoiGian = config.caSang;
        break;
      case CaDiemDanh.trua:
        thoiGian = config.caTrua;
        break;
      case CaDiemDanh.chieuToi:
        thoiGian = config.caChieuToi;
        break;
    }

    // Parse end time
    final endTimeParts = thoiGian.ketThuc.split(':');
    final endHour = int.parse(endTimeParts[0]);
    final endMinute = int.parse(endTimeParts[1]);
    final endTime = DateTime(
      checkInTime.year,
      checkInTime.month,
      checkInTime.day,
      endHour,
      endMinute,
    );

    // Compare check-in time with end time
    if (checkInTime.isBefore(endTime) ||
        checkInTime.isAtSameMomentAs(endTime)) {
      return TrangThaiDiemDanh.dungGio;
    } else {
      return TrangThaiDiemDanh.tre;
    }
  }

  /// Check if student has approved leave for a date
  static Future<bool> checkIsOnLeave(String idHocSinh, DateTime date) async {
    try {
      final approvedLeaves = await XinVePhepService.getApprovedByMealDate(date);
      return approvedLeaves.any((leave) => leave.idHocSinh == idHocSinh);
    } catch (e) {
      return false;
    }
  }

  /// Get attendance record for a student on a specific date and period
  static Future<DiemDanh?> getByStudentAndDate(
    String idHocSinh,
    DateTime date,
    CaDiemDanh ca,
  ) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nextDay = dateOnly.add(const Duration(days: 1));

    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('id_hoc_sinh', isEqualTo: idHocSinh)
        .where('ngay', isGreaterThanOrEqualTo: Timestamp.fromDate(dateOnly))
        .where('ngay', isLessThan: Timestamp.fromDate(nextDay))
        .where('ca', isEqualTo: DiemDanh.caToString(ca))
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return DiemDanh.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  /// Get attendance history for a student within date range
  static Future<List<DiemDanh>> getByStudent(
    String idHocSinh,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('id_hoc_sinh', isEqualTo: idHocSinh)
        .where('ngay', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('ngay', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('ngay', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => DiemDanh.fromFirestore(doc))
        .toList();
  }

  /// Get attendance records for a class on a specific date
  static Future<List<DiemDanh>> getByClass(String idLop, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nextDay = dateOnly.add(const Duration(days: 1));

    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('id_lop', isEqualTo: idLop)
        .where('ngay', isGreaterThanOrEqualTo: Timestamp.fromDate(dateOnly))
        .where('ngay', isLessThan: Timestamp.fromDate(nextDay))
        .orderBy('ngay', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => DiemDanh.fromFirestore(doc))
        .toList();
  }

  /// Get late records for a student within date range
  static Future<List<DiemDanh>> getLateByStudent(
    String idHocSinh,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('id_hoc_sinh', isEqualTo: idHocSinh)
        .where('trang_thai', isEqualTo: 'tre')
        .where('ngay', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('ngay', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('ngay', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => DiemDanh.fromFirestore(doc))
        .toList();
  }

  /// Get late records for a class within date range
  static Future<List<DiemDanh>> getLateByClass(
    String idLop,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('id_lop', isEqualTo: idLop)
        .where('trang_thai', isEqualTo: 'tre')
        .where('ngay', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('ngay', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('ngay', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => DiemDanh.fromFirestore(doc))
        .toList();
  }

  /// Get late statistics for a class
  static Future<Map<String, int>> getLateStatistics(
    String idLop,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final lateRecords = await getLateByClass(idLop, startDate, endDate);

    // Count unique students who were late
    final lateStudentIds = <String>{};
    for (final record in lateRecords) {
      lateStudentIds.add(record.idHocSinh);
    }

    // Get total students in class
    final students = await HocSinhService.getHocSinhByLop(idLop);
    final totalStudents = students.length;

    return {
      'total_students': totalStudents,
      'late_count': lateRecords.length,
      'late_students': lateStudentIds.length,
    };
  }

  /// Get all late records for a date (across all classes)
  static Future<List<DiemDanh>> getLateByDate(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nextDay = dateOnly.add(const Duration(days: 1));

    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('trang_thai', isEqualTo: 'tre')
        .where('ngay', isGreaterThanOrEqualTo: Timestamp.fromDate(dateOnly))
        .where('ngay', isLessThan: Timestamp.fromDate(nextDay))
        .get();

    return querySnapshot.docs
        .map((doc) => DiemDanh.fromFirestore(doc))
        .toList();
  }

  /// Get today's attendance for a student
  static Future<List<DiemDanh>> getTodayByStudent(String idHocSinh) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('id_hoc_sinh', isEqualTo: idHocSinh)
        .where('ngay', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('ngay', isLessThan: Timestamp.fromDate(tomorrow))
        .get();

    return querySnapshot.docs
        .map((doc) => DiemDanh.fromFirestore(doc))
        .toList();
  }

  /// Determine current period based on time and config
  static CaDiemDanh? getCurrentPeriod(CaHocConfig config) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Parse time periods
    debugPrint('huynd: CaHocConfig: $CaHocConfig');
    final sangStart = _parseTimeToMinutes(config.caSang.batDau);
    final sangEnd = _parseTimeToMinutes(config.caSang.ketThuc);
    final truaStart = _parseTimeToMinutes(config.caTrua.batDau);
    final truaEnd = _parseTimeToMinutes(config.caTrua.ketThuc);
    final chieuStart = _parseTimeToMinutes(config.caChieuToi.batDau);
    final chieuEnd = _parseTimeToMinutes(config.caChieuToi.ketThuc);

    // Check which period we're in (with 30 min buffer after end)
    if (currentMinutes >= sangStart && currentMinutes <= sangEnd + 30) {
      return CaDiemDanh.sang;
    } else if (currentMinutes >= truaStart && currentMinutes <= truaEnd + 30) {
      return CaDiemDanh.trua;
    } else if (currentMinutes >= chieuStart &&
        currentMinutes <= chieuEnd + 30) {
      return CaDiemDanh.chieuToi;
    }

    return null; // No active period
  }

  static int _parseTimeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // ==================== ABSENCE TRACKING ====================

  /// Kiểm tra ca điểm danh đã kết thúc chưa
  /// Thời điểm hiện tại > thời gian kết thúc ca thì tính là đã kết thúc ca
  static bool isPeriodEnded(CaHocConfig config, CaDiemDanh ca, DateTime date) {
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);

    // Nếu thời điểm hiện tại là ngày trong quá khứ thì ca điểm danh đã kết thúc
    if (dateOnly.isBefore(DateTime(now.year, now.month, now.day))) {
      return true;
    }

    // Nếu thời điểm hiện tại là ngày trong tương lai thì ca điểm danh chưa kết thúc
    if (dateOnly.isAfter(DateTime(now.year, now.month, now.day))) {
      return false;
    }

    // Nếu cùng 1 ngày thì kiểm tra xem thời điểm hiện tại có sau thời điểm kết thúc ca hay k
    ThoiGianCa thoiGian;
    switch (ca) {
      case CaDiemDanh.sang:
        thoiGian = config.caSang;
        break;
      case CaDiemDanh.trua:
        thoiGian = config.caTrua;
        break;
      case CaDiemDanh.chieuToi:
        thoiGian = config.caChieuToi;
        break;
    }

    final endMinutes = _parseTimeToMinutes(thoiGian.ketThuc);
    final currentMinutes = now.hour * 60 +
        now.minute; //Thời điểm hiện tại > thời gian kết thúc ca thì tính là đã kết thúc ca

    return currentMinutes > endMinutes;
  }

  /// Lấy ra danh sách học sinh vắng mặt theo ca và số lượng học sinh vắng mặt
  /// Vắng = Tổng - đã_điểm_danh - nghỉ_phép
  static Future<List<String>> getAbsentStudentIds({
    required String idLop,
    required DateTime date,
    required CaDiemDanh ca,
  }) async {
    // Lấy ra tất cả học sinh
    final students = await HocSinhService.getHocSinhByLop(idLop);
    final allStudentIds = students.map((s) => s.id!).toSet();

    // Lấy ra học sinh đã điểm danh
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nextDay = dateOnly.add(const Duration(days: 1));

    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('id_lop', isEqualTo: idLop)
        .where('ngay', isGreaterThanOrEqualTo: Timestamp.fromDate(dateOnly))
        .where('ngay', isLessThan: Timestamp.fromDate(nextDay))
        .where('ca', isEqualTo: DiemDanh.caToString(ca))
        .get();

    final checkedInIds = querySnapshot.docs
        .map((doc) => doc.data()['id_hoc_sinh'] as String)
        .toSet();

    // Lấy ra học sinh đã xin về phép
    final approvedLeaves = await XinVePhepService.getApprovedByMealDate(date);
    final onLeaveIds = approvedLeaves.map((l) => l.idHocSinh).toSet();

    // Vắng = Tổng - đã_điểm_danh - nghỉ_phép
    final absentIds =
        allStudentIds.difference(checkedInIds).difference(onLeaveIds).toList();

    return absentIds;
  }

  /// Get absence statistics for a class on a date
  /// Returns map with counts per period
  static Future<Map<String, dynamic>> getAbsenceStatistics(
    String idLop,
    DateTime date,
  ) async {
    final lop = await LopService.getLopById(idLop);
    final config =
        lop?.getConfigForDay(date.weekday) ?? CaHocConfig.defaultConfig();

    final result = <String, dynamic>{
      'sang': <String>[],
      'trua': <String>[],
      'chieuToi': <String>[],
      'total_absent': 0,
    };

    // Tính số học sinh vắng theo từng ca
    for (final ca in CaDiemDanh.values) {
      // Logic mới: Tính cả ca đã kết thúc HOẶC ca đang diễn ra (đã qua giờ bắt đầu)
      if (isPeriodStarted(config, ca, date)) {
        final absentIds = await getAbsentStudentIds(
          idLop: idLop,
          date: date,
          ca: ca,
        );
        final key = DiemDanh.caToString(ca);
        result[key] = absentIds;
      }
    }

    // Tính toán ra tổng số học sinh vắng của các ca (logic: vắng tất cả các ca đã diễn ra)
    Set<String>? commonAbsentIds;
    for (final ca in CaDiemDanh.values) {
      if (isPeriodStarted(config, ca, date)) {
        final key = DiemDanh.caToString(ca);
        final ids = (result[key] as List<String>? ?? <String>[]).toSet();

        if (commonAbsentIds == null) {
          commonAbsentIds = ids;
        } else {
          commonAbsentIds = commonAbsentIds.intersection(ids);
        }
      }
    }

    final allAbsentIds = commonAbsentIds?.toList() ?? <String>[];
    result['total_absent'] = allAbsentIds.length;
    result['all_absent_ids'] = allAbsentIds;

    return result;
  }

  /// Kiểm tra ca học đã bắt đầu chưa (tính cả đang diễn ra hoặc đã kết thúc)
  static bool isPeriodStarted(
      CaHocConfig config, CaDiemDanh ca, DateTime date) {
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);

    // Ngày quá khứ -> Đã bắt đầu (và kết thúc)
    if (dateOnly.isBefore(DateTime(now.year, now.month, now.day))) {
      return true;
    }
    // Ngày tương lai -> Chưa bắt đầu
    if (dateOnly.isAfter(DateTime(now.year, now.month, now.day))) {
      return false;
    }

    // Cùng ngày -> Check giờ bắt đầu
    ThoiGianCa thoiGian;
    switch (ca) {
      case CaDiemDanh.sang:
        thoiGian = config.caSang;
        break;
      case CaDiemDanh.trua:
        thoiGian = config.caTrua;
        break;
      case CaDiemDanh.chieuToi:
        thoiGian = config.caChieuToi;
        break;
    }

    final startMinutes = _parseTimeToMinutes(thoiGian.batDau);
    final currentMinutes = now.hour * 60 + now.minute;

    return currentMinutes >= startMinutes;
  }

  /// Get absence history for a student within date range
  /// Returns list of {date, ca} records where student was absent
  static Future<List<Map<String, dynamic>>> getAbsencesByStudent(
    String idHocSinh,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final absences = <Map<String, dynamic>>[];

    // Get student's class
    final student = await HocSinhService.getHocSinhById(idHocSinh);
    if (student == null) {
      return absences;
    }

    final idLop = student.idLop;
    final lop = await LopService.getLopById(idLop);

    // Get all attendance records for this student in date range
    final attendanceRecords = await getByStudent(idHocSinh, startDate, endDate);

    // Get all approved leave dates
    final approvedLeaves = await XinVePhepService.getApprovedByStudentDateRange(
      idHocSinh,
      startDate,
      endDate,
    );
    final leaveDates = <DateTime>{};
    for (final leave in approvedLeaves) {
      for (final d in leave.danhSachNgayCatCom) {
        leaveDates.add(DateTime(d.year, d.month, d.day));
      }
    }

    // Iterate through each day in range
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

    while (!currentDate.isAfter(endDateOnly)) {
      // Skip leave days
      if (leaveDates.contains(currentDate)) {
        currentDate = currentDate.add(const Duration(days: 1));
        continue;
      }

      // Logic mới: Nếu học sinh đã check-in bất kỳ ca nào trong ngày -> Tính là có đi học -> Skip
      final hasAnyRecordInDay = attendanceRecords.any((r) =>
          r.ngay.year == currentDate.year &&
          r.ngay.month == currentDate.month &&
          r.ngay.day == currentDate.day);

      if (hasAnyRecordInDay) {
        currentDate = currentDate.add(const Duration(days: 1));
        continue;
      }

      final config = lop?.getConfigForDay(currentDate.weekday) ??
          CaHocConfig.defaultConfig();

      // Check each period
      for (final ca in CaDiemDanh.values) {
        // Only check ended periods
        if (!isPeriodEnded(config, ca, currentDate)) continue;

        // Vì đã check hasAnyRecordInDay ở trên và = false, nên chắc chắn k có record nào
        // Chỉ cần check xem ca đã kết thúc chưa để báo vắng
        absences.add({
          'date': currentDate,
          'ca': ca,
        });
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return absences;
  }
}
