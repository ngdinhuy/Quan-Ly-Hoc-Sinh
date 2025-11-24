# Implementation Tasks

## Status
**Pending approval**

## Overview
Add absence tracking to the attendance system - track students who haven't checked in, display in admin statistics, and show to parents.

## Phase 1: Service Layer

### Task 1.1: Add absence calculation methods to DiemDanhService
- **File**: `lib/services/diem_danh_service.dart`
- **Description**: Add methods to calculate absent students
- **Details**:
  - Add `getAbsentStudentIds(idLop, date, ca)` - returns list of student IDs who are absent
  - Add `getAbsenceStatistics(idLop, date)` - returns absence counts per period
  - Add `isPeriodEnded(config, ca)` - check if period has ended (for valid absence calculation)
- **Validation**: Methods return correct absent student lists

### Task 1.2: Add absence query method for student
- **File**: `lib/services/diem_danh_service.dart`
- **Description**: Add method to get absence history for a student
- **Details**:
  - Add `getAbsencesByStudent(idHocSinh, startDate, endDate)` - returns dates/periods where student was absent
  - Should check each period of each day in range
  - Exclude days with approved leave
- **Validation**: Returns correct absence history

## Phase 2: Admin Statistics Enhancement

### Task 2.1: Update statistics data model
- **File**: `lib/screens/thong_ke_di_muon_screen.dart`
- **Description**: Extend `_ClassLateStats` to include absence data
- **Details**:
  - Add `absentCount` field (total absence records)
  - Add `absentStudents` field (unique absent students)
  - Add `absentStudentIds` list for detail view
- **Validation**: Model holds absence data

### Task 2.2: Update statistics loading logic
- **File**: `lib/screens/thong_ke_di_muon_screen.dart`
- **Description**: Load absence data alongside late data
- **Details**:
  - Call `DiemDanhService.getAbsentStudentIds()` for each period
  - Populate absence fields in `_ClassLateStats`
  - Only count absences for ended periods
- **Validation**: Absence stats load correctly

### Task 2.3: Update statistics UI
- **File**: `lib/screens/thong_ke_di_muon_screen.dart`
- **Description**: Display absence data in UI
- **Details**:
  - Rename screen title to "Thống Kê Điểm Danh"
  - Add summary card for "Vắng mặt" count
  - Add "Vắng" column to DataTable
  - Update column headers: Đúng giờ | Muộn | Vắng
- **Validation**: UI shows absence counts

### Task 2.4: Update detail dialog
- **File**: `lib/screens/thong_ke_di_muon_screen.dart`
- **Description**: Show absent students in detail view
- **Details**:
  - Add tabs: "Đi muộn" | "Vắng mặt"
  - Show absent student names with period info
  - Fetch student names from HocSinhService
- **Validation**: Detail shows both late and absent students

## Phase 3: Parent Absence History

### Task 3.1: Create parent absence history screen
- **File**: `lib/screens/phu_huynh/lich_su_vang_mat/lich_su_vang_mat_screen.dart`
- **Description**: Screen showing child's absence history
- **Details**:
  - Date range picker (default: last 30 days)
  - List of absences: date, period
  - Empty state message when no absences
  - Similar structure to `lich_su_di_muon_phu_huynh_screen.dart`
- **Validation**: Shows correct absence history

### Task 3.2: Add navigation to parent main screen
- **File**: `lib/screens/phu_huynh/main_phu_huynh/main_phu_huynh_screen.dart`
- **Description**: Add action card for absence history
- **Details**:
  - Add "Lịch Sử Vắng Mặt" action card
  - Icon: `Icons.event_busy`
  - Color: `Colors.red`
  - Navigate to `LichSuVangMatScreen`
- **Validation**: Navigation works

## Phase 4: Cleanup and Documentation

### Task 4.1: Update admin navigation menu text
- **File**: `lib/screens/main_screen.dart`
- **Description**: Rename menu item from "Thống kê đi muộn" to "Thống kê điểm danh"
- **Validation**: Menu shows correct text

### Task 4.2: Update documentation
- **File**: `CLAUDE.md`
- **Description**: Update attendance tracking documentation
- **Details**:
  - Add absence tracking description
  - Document absence calculation logic
  - List new files created
- **Validation**: Documentation accurate

## Implementation Notes

### Absence Calculation Logic
```dart
// For each period (sang, trua, chieuToi):
1. Get all students in class
2. Get students who checked in (any status)
3. Get students with approved leave
4. Absent = all - checkedIn - onLeave
```

### Period Status for Statistics
- Show absence count only for ended periods
- For ongoing/future periods, show "-" or "N/A"
- A period is "ended" when current time > period end + 30 min buffer

### Files to Create
- `lib/screens/phu_huynh/lich_su_vang_mat/lich_su_vang_mat_screen.dart`

### Files to Modify
- `lib/services/diem_danh_service.dart` (add absence methods)
- `lib/screens/thong_ke_di_muon_screen.dart` (add absence UI)
- `lib/screens/phu_huynh/main_phu_huynh/main_phu_huynh_screen.dart` (add navigation)
- `lib/screens/main_screen.dart` (rename menu item)
- `CLAUDE.md` (update docs)
