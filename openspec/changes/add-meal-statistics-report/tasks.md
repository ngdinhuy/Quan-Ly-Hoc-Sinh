# Implementation Tasks

## Status
**All tasks completed**

## Overview
Create a web admin screen for meal statistics reporting, showing daily meal counts by class with Excel export functionality.

## Phase 1: Service Layer

### Task 1.1: Add query method to XinVePhepService ✅
- **File**: `lib/services/xin_ve_phep_service.dart`
- **Description**: Add method to get approved leave permissions containing a specific meal deduction date
- **Details**:
  - Added `static Future<List<XinVePhep>> getApprovedByMealDate(DateTime date)`
  - Added `static Future<List<XinVePhep>> getApprovedInDateRange(DateTime start, DateTime end)`
  - Query: `where('trang_thai', isEqualTo: 'da_duyet')`
  - Filter in Dart: check if `danh_sach_ngay_cat_com` contains the date
- **Validation**: ✅ Completed

### Task 1.2: Create ThongKeXuatAnService ✅
- **File**: `lib/services/thong_ke_xuat_an_service.dart`
- **Description**: Create service for meal statistics calculations
- **Details**:
  - Created `MealStatistics` model class with `idLop`, `tenLop`, `tongHocSinh`, `soCatCom`, and computed `soAnCom`
  - Added `getStatisticsByDate(DateTime date)` method
  - Added `getStatisticsByClassAndDate(String idLop, DateTime date)` method
  - Added `getMonthlyOverview(int year, int month)` method
- **Validation**: ✅ Completed

### Task 1.3: Add Excel export functionality ✅
- **File**: `lib/services/thong_ke_xuat_an_service.dart` (continue)
- **Description**: Add methods to generate Excel files
- **Details**:
  - Added `excel: ^4.0.6` package to pubspec.yaml
  - Added `exportDailyToExcel(DateTime date, List<MealStatistics> stats)` method
  - Added `exportMonthlyToExcel(int year, int month, Map<DateTime, int> data, List<Lop> classes)` method
- **Validation**: ✅ Completed

## Phase 2: UI Implementation

### Task 2.1: Create ThongKeXuatAnScreen ✅
- **File**: `lib/screens/thong_ke_xuat_an_screen.dart`
- **Description**: Create main statistics screen with date picker and data table
- **Details**:
  - Created StatefulWidget with TabController for daily/monthly views
  - Daily view: date picker, class filter dropdown, DataTable with statistics
  - Summary row at bottom with totals
  - Loading and error states handled
- **Validation**: ✅ Completed

### Task 2.2: Add monthly overview tab ✅
- **File**: `lib/screens/thong_ke_xuat_an_screen.dart` (continue)
- **Description**: Add tab for monthly overview
- **Details**:
  - Two tabs: "Theo ngày" and "Theo tháng"
  - Month/year picker dialog
  - Table view with daily totals and day of week
  - Summary cards showing total and average
  - Click on day navigates to daily view
- **Validation**: ✅ Completed

### Task 2.3: Implement Excel download ✅
- **File**: `lib/screens/thong_ke_xuat_an_screen.dart` (continue)
- **Description**: Connect export button to download functionality
- **Details**:
  - Added `web: ^1.1.0` package for browser download
  - Export button in AppBar works for both tabs
  - Loading indicator during export
  - Success/error snackbar notifications
  - File downloads with correct naming convention
- **Validation**: ✅ Completed

## Phase 3: Integration

### Task 3.1: Add navigation to admin menu ✅
- **File**: `lib/screens/main_screen.dart`
- **Description**: Add menu item to access meal statistics
- **Details**:
  - Added import for `ThongKeXuatAnScreen`
  - Added to `_screens` list with `_canAccess('thong_ke_xuat_an')`
  - Added to `_titles` list: "Thống Kê Xuất Ăn"
  - Added menu item with `Icons.restaurant_menu` icon
- **Validation**: ✅ Completed

### Task 3.2: Code formatting and cleanup ✅
- **Description**: Final cleanup
- **Details**:
  - Ran `dart format` on all new/modified files
  - Ran `flutter analyze` - only info-level warnings (curly braces style)
  - No errors in new code
- **Validation**: ✅ Completed

### Task 3.3: Update documentation ✅
- **File**: `CLAUDE.md`
- **Description**: Document the new meal statistics feature
- **Details**:
  - Added "Meal Statistics (Thống Kê Xuất Ăn)" section under Leave Permission System
  - Documented key features, calculations, data source, and related files
  - Listed dependencies (excel, web packages)
- **Validation**: ✅ Completed

## Implementation Notes

### Data Flow
1. User selects date →
2. Service queries approved `xin_ve_phep` with `danh_sach_ngay_cat_com` containing date →
3. Group by class, count deductions →
4. Calculate: Ăn cơm = Tổng HS - Cắt cơm →
5. Display in table

### Key Calculations
- **Tổng HS**: Count from `hoc_sinh` collection where `id_lop` matches
- **Cắt cơm**: Count distinct `id_hoc_sinh` from approved `xin_ve_phep` where `danh_sach_ngay_cat_com` contains selected date
- **Ăn cơm**: Tổng HS - Cắt cơm

### Edge Cases
- Student with multiple approved leave permissions on same date: count only once
- Class with no students: show 0/0/0
- No approved leave permissions: all classes show Cắt cơm = 0

### Dependencies
- `excel: ^4.0.6` package for Excel export
- `web: ^1.1.0` package for browser download

### Files Created/Modified
- **New files:**
  - `lib/screens/thong_ke_xuat_an_screen.dart`
  - `lib/services/thong_ke_xuat_an_service.dart`
- **Modified files:**
  - `lib/services/xin_ve_phep_service.dart` (added query methods)
  - `lib/screens/main_screen.dart` (added navigation)
  - `pubspec.yaml` (added dependencies)
  - `CLAUDE.md` (added documentation)
