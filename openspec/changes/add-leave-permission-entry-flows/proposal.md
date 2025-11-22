# Add Teacher/Admin and Parent Leave Permission Entry

## Why
The leave permission system currently only supports student-submitted requests. Teachers need to manually enter leave permissions when parents submit requests via phone or paper forms. Parents should be able to submit requests directly from their app instead of requiring the student to do it. The `XinVePhep` model already supports these flows via `NguonVePhep.giaoVienNhap` and `NguonVePhep.appPhuHuynh` enums, but the UI is missing.

## What Changes
- Add teacher/admin web form dialog for manual leave permission entry with student search
- Add parent mobile app screens for leave permission requests with auto-filled guardian info
- Add navigation from parent main menu to new leave request/history screens
- Add "Create New" button to teacher approval screen for manual entry
- Update detail dialog to properly display teacher and parent sources
- Optionally support pre-approval for teacher-entered permissions

## Impact
- **Affected specs**:
  - teacher-admin-entry (new capability)
  - parent-request (new capability)
- **Affected code**:
  - `lib/widgets/giao_vien_nhap_ve_phep_form_dialog.dart` (new file)
  - `lib/screens/phu_huynh/xin_ve_phep/dang_ky_ve_phep_phu_huynh_screen.dart` (new file)
  - `lib/screens/phu_huynh/xin_ve_phep/lich_su_ve_phep_phu_huynh_screen.dart` (new file)
  - `lib/screens/phu_huynh/main_phu_huynh/main_phu_huynh_screen.dart` (modified - add navigation)
  - `lib/screens/giao_vien/duyet_ve_phep/duyet_ve_phep_screen.dart` (modified - add create button)
  - `lib/widgets/xin_ve_phep_detail_dialog.dart` (verify source display)
- **Dependencies**:
  - Reuses `XinVePhepService`, `validation_utils.dart`, `XinVePhep` model
  - Requires `PhuHuynh` and `HocSinh` models/services for auto-fill
- **Breaking changes**: None
