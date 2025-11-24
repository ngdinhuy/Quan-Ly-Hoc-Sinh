# Add Student Attendance Tracking

## Why

The school needs to track student attendance for 3 daily periods (morning, noon, afternoon/evening) to monitor late arrivals. Teachers, parents, and administrators need visibility into attendance patterns, and students with approved leave permissions should not be marked as late.

## What Changes

- **NEW**: Configurable attendance time periods per class per weekday (web admin only)
- **NEW**: Student check-in via card scan and face scan on mobile app
- **NEW**: Late history viewing for homeroom teachers and parents
- **NEW**: Admin statistics screen for late students by class and day
- **INTEGRATION**: Skip late marking for days with approved leave permissions (`xin_ve_phep`)

## Impact

- **Affected specs**: New capabilities (no existing specs affected)
- **Affected code**:
  - `lib/models/lop.dart` - Add embedded attendance config map
  - `lib/models/diem_danh.dart` - New model for check-in records
  - `lib/services/lop_service.dart` - Add attendance config update methods
  - `lib/services/diem_danh_service.dart` - New service for check-in management
  - `lib/screens/` - New screens for admin config, student check-in, teacher/parent history, admin statistics
  - `lib/screens/hoc_sinh/xac_thuc_khuon_mat/` - Reuse camera/face logic
  - `lib/screens/hoc_sinh/xac_thuc_the/` - Reuse card scan logic
  - `lib/screens/main_screen.dart` - Add admin menu items
  - `lib/services/xin_ve_phep_service.dart` - Query for leave permission dates
