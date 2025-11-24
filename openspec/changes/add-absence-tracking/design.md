# Design: Absence Tracking

## Overview

This design extends the existing attendance tracking system to include absence detection and reporting.

## Data Model

### No New Collections
Absences are calculated on-demand, not stored as records. This simplifies the system and avoids data duplication.

### Calculation Formula
```
Absent Students = All Students in Class
                - Students with Check-in Record
                - Students with Approved Leave
```

## Service Layer Changes

### DiemDanhService Additions

```dart
/// Get students who are absent for a specific period
/// Returns list of student IDs who haven't checked in and don't have leave
static Future<List<String>> getAbsentStudentIds({
  required String idLop,
  required DateTime date,
  required CaDiemDanh ca,
}) async {
  // 1. Get all students in class
  // 2. Get students who checked in for this period
  // 3. Get students with approved leave for this date
  // 4. Return: all - checkedIn - onLeave
}

/// Get absence statistics for a class on a date
static Future<Map<String, int>> getAbsenceStatistics(
  String idLop,
  DateTime date,
) async {
  // Returns count of absent students per period
}
```

## UI Changes

### Admin Statistics Screen (`thong_ke_di_muon_screen.dart`)

**Current columns**: Lớp | Tổng HS | Số lượt muộn | Số HS muộn | Tỷ lệ | Chi tiết

**New columns**: Lớp | Tổng HS | Đúng giờ | Muộn | Vắng | Chi tiết

**Summary cards**: Add "Vắng mặt" card alongside existing cards

**Detail dialog**: Add tab/section for absent students (show student name, period)

### Parent Absence History Screen

New screen: `lib/screens/phu_huynh/lich_su_vang_mat/lich_su_vang_mat_screen.dart`

Features:
- Date range filter (default: last 30 days)
- List of absence records showing: date, period
- Empty state when no absences

### Parent Main Screen

Add action card: "Lịch Sử Vắng Mặt" with link to absence history

## Period End Detection

To determine if a period has ended (and absences can be calculated):

```dart
bool isPeriodEnded(CaHocConfig config, CaDiemDanh ca) {
  final now = DateTime.now();
  final endTime = getEndTimeForPeriod(config, ca);
  // Add 30-minute buffer after period end
  return now.isAfter(endTime.add(Duration(minutes: 30)));
}
```

Only show absence counts for periods that have ended.

## Edge Cases

1. **Mid-period query**: If querying statistics before period ends, absence count shows "N/A" or "-"
2. **No class config**: Use default periods for absence calculation
3. **Student joined mid-day**: Student not counted as absent for periods before they joined (out of scope - treat as absent)

## Integration Points

- `HocSinhService.getHocSinhByLop()` - Get all students in class
- `DiemDanhService.getByClass()` - Get check-in records
- `XinVePhepService.getApprovedByMealDate()` - Get students on leave
