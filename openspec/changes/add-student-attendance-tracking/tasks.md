# Implementation Tasks

## Status
**Pending approval**

## Overview
Implement student attendance tracking with configurable time periods, mobile check-in, and late statistics.

## Phase 1: Data Model & Service Layer

### Task 1.1: Update Lop model with attendance config
- **File**: `lib/models/lop.dart`
- **Description**: Add attendance time period configuration as embedded map
- **Details**:
  - Add `Map<String, CaHocConfig>? cauHinhDiemDanh` field (key = day of week "1"-"7")
  - Create helper class `CaHocConfig` with `caSang`, `caTrua`, `caChieuToi` (each has `batDau`, `ketThuc` as String "HH:mm")
  - Update `fromFirestore()` and `toFirestore()` to handle the new field
  - Update `copyWith()` method
- **Validation**: Model compiles without errors

### Task 1.2: Create DiemDanh model
- **File**: `lib/models/diem_danh.dart`
- **Description**: Create model for attendance records
- **Details**:
  - Fields: `idHocSinh`, `idLop`, `ngay`, `ca` (enum: sang/trua/chieuToi), `thoiGianCheckin`, `phuongThuc`, `trangThai` (enum: dungGio/tre/vangPhep)
  - Include `fromFirestore()` and `toFirestore()` methods
  - Include `copyWith()` method
- **Validation**: Model compiles without errors

### Task 1.3: Update LopService with config methods
- **File**: `lib/services/lop_service.dart`
- **Description**: Add methods to update attendance config
- **Details**:
  - `updateAttendanceConfig(idLop, config)` - Update config for a class
  - `getDefaultAttendanceConfig()` - Return default time periods
- **Validation**: Service methods work with Firestore

### Task 1.4: Create DiemDanhService
- **File**: `lib/services/diem_danh_service.dart`
- **Description**: Attendance check-in and query operations
- **Details**:
  - `checkIn(idHocSinh, ca, phuongThuc)` - Record with late calculation
  - `getByStudent(idHocSinh, startDate, endDate)` - History query
  - `getByClass(idLop, date)` - Class attendance for day
  - `getLateByClass(idLop, startDate, endDate)` - Late records only
  - `getLateStatistics(idLop, startDate, endDate)` - Aggregated counts
  - `isOnLeave(idHocSinh, date)` - Check approved leave
  - `calculateLateStatus(checkInTime, config, studentId, date)` - Determine status
- **Validation**: Service correctly calculates late status

## Phase 2: Shared Widgets

### Task 2.1: Extract CardCameraWidget
- **File**: `lib/widgets/card_camera_widget.dart`
- **Description**: Reusable card scanning camera widget
- **Details**:
  - Extract camera initialization and overlay from `XacThucTheScreen`
  - Callback `onImageCaptured(Uint8List bytes)`
  - Props: `overlayText`, `onCapture`
- **Validation**: Widget works independently

### Task 2.2: Extract FaceCameraWidget
- **File**: `lib/widgets/face_camera_widget.dart`
- **Description**: Reusable face scanning camera widget
- **Details**:
  - Extract camera initialization and overlay from `XacThucKhuonMatScreen`
  - Use front camera by default
  - Callback `onImageCaptured(Uint8List bytes)`
  - Props: `overlayText`, `onCapture`
- **Validation**: Widget works independently

## Phase 3: Admin Configuration Screen (Web)

### Task 3.1: Create CauHinhDiemDanhScreen
- **File**: `lib/screens/cau_hinh_diem_danh_screen.dart`
- **Description**: Admin screen to configure attendance periods
- **Details**:
  - Class dropdown selector
  - 7 tabs for weekdays (Thứ 2 - CN)
  - 3 time period inputs per day (Sáng, Trưa, Chiều tối)
  - Time picker for start/end
  - Save/Reset buttons
  - Copy from another day feature
- **Validation**: Config saved to Firestore

### Task 3.2: Add navigation to admin menu
- **File**: `lib/screens/main_screen.dart`
- **Description**: Add menu item for attendance config
- **Details**:
  - Add `_canAccess('cau_hinh_diem_danh')` check
  - Add to `_screens`, `_titles`, `_buildMenuItems`
  - Icon: `Icons.schedule`
- **Validation**: Menu item visible for admin

## Phase 4: Student Check-in Screen (Mobile)

### Task 4.1: Create DiemDanhScreen
- **File**: `lib/screens/hoc_sinh/diem_danh/diem_danh_screen.dart`
- **Description**: Student attendance check-in screen
- **Details**:
  - Show current period (based on time)
  - Two options: Card scan / Face scan
  - Use `CardCameraWidget` and `FaceCameraWidget`
  - Show today's attendance status
  - Handle duplicate check-in (show already checked in)
- **Validation**: Check-in recorded correctly

### Task 4.2: Add navigation to student menu
- **File**: `lib/screens/hoc_sinh/hoc_sinh_main_screen.dart`
- **Description**: Add check-in option to student main screen
- **Details**:
  - Add prominent check-in button
  - Show current period status
- **Validation**: Navigation works

## Phase 5: Late History Screen

### Task 5.1: Create LichSuDiMuonScreen (Teacher)
- **File**: `lib/screens/giao_vien/lich_su_di_muon/lich_su_di_muon_screen.dart`
- **Description**: Homeroom teacher view of late arrivals
- **Details**:
  - Filter by date range
  - Show only homeroom class students
  - List with: student name, date, period, check-in time
  - Export to Excel (optional)
- **Validation**: Only shows homeroom class

### Task 5.2: Create LichSuDiMuonPhuHuynhScreen (Parent)
- **File**: `lib/screens/phu_huynh/lich_su_di_muon/lich_su_di_muon_phu_huynh_screen.dart`
- **Description**: Parent view of child's late history
- **Details**:
  - Auto-filter to linked student
  - Date range picker
  - List with: date, period, check-in time
- **Validation**: Only shows linked student

## Phase 6: Admin Statistics Screen (Web)

### Task 6.1: Create ThongKeDiMuonScreen
- **File**: `lib/screens/thong_ke_di_muon_screen.dart`
- **Description**: Admin statistics for late arrivals
- **Details**:
  - Daily view tab: date picker, class filter, DataTable
  - Columns: class, total students, late count, late percentage
  - Click row to see late student list
  - Export to Excel
- **Validation**: Statistics accurate

### Task 6.2: Add navigation to admin menu
- **File**: `lib/screens/main_screen.dart`
- **Description**: Add menu item for late statistics
- **Details**:
  - Add `_canAccess('thong_ke_di_muon')` check
  - Add to `_screens`, `_titles`, `_buildMenuItems`
  - Icon: `Icons.warning_amber`
- **Validation**: Menu item visible for admin

## Phase 7: Integration & Testing

### Task 7.1: Integrate leave permission check
- **File**: `lib/services/diem_danh_service.dart`
- **Description**: Check approved leave before marking late
- **Details**:
  - Query `xin_ve_phep` with approved status
  - Check if date falls in leave range or `danh_sach_ngay_cat_com`
  - Mark as `vangPhep` instead of `tre` if on leave
- **Validation**: Leave days not marked as late

### Task 7.2: Code formatting and cleanup
- **Description**: Final cleanup
- **Details**:
  - Run `dart format` on all new/modified files
  - Run `flutter analyze`
  - Fix any errors or warnings
- **Validation**: No errors in new code

### Task 7.3: Update documentation
- **File**: `CLAUDE.md`
- **Description**: Document the attendance tracking feature
- **Details**:
  - Add "Student Attendance Tracking (Điểm Danh)" section
  - Document key features, calculations, data flow
  - List related files
- **Validation**: Documentation accurate

## Implementation Notes

### Data Flow: Check-in
1. Student opens check-in screen
2. System determines current period based on class config and time
3. Student scans card or face
4. System verifies identity (existing `ImageService`)
5. System checks for approved leave on this date
6. System calculates late status (on-time/late/excused)
7. System saves attendance record
8. UI shows confirmation

### Late Status Calculation
1. Get class attendance config for today's weekday
2. Get period start time for selected period
3. If student has approved leave → `vangPhep`
4. If check-in time ≤ period end time → `dungGio`
5. Else → `tre`

### Edge Cases
- No config for class/day: Use default times or show error
- Student checks in outside any period: Record but mark period based on closest
- Student on leave checks in: Still record, but status is `vangPhep`

### Dependencies
- Existing: `camera`, `permission_handler`, `image_service.dart`
- No new packages required

### Files to Create
- `lib/models/diem_danh.dart`
- `lib/services/diem_danh_service.dart`
- `lib/widgets/card_camera_widget.dart`
- `lib/widgets/face_camera_widget.dart`
- `lib/screens/cau_hinh_diem_danh_screen.dart`
- `lib/screens/hoc_sinh/diem_danh/diem_danh_screen.dart`
- `lib/screens/giao_vien/lich_su_di_muon/lich_su_di_muon_screen.dart`
- `lib/screens/phu_huynh/lich_su_di_muon/lich_su_di_muon_phu_huynh_screen.dart`
- `lib/screens/thong_ke_di_muon_screen.dart`

### Files to Modify
- `lib/models/lop.dart` (add `cauHinhDiemDanh` field with `CaHocConfig` helper class)
- `lib/services/lop_service.dart` (add attendance config methods)
- `lib/screens/main_screen.dart` (add admin menu items)
- `lib/screens/hoc_sinh/hoc_sinh_main_screen.dart` (add check-in navigation)
- `CLAUDE.md` (add documentation)
