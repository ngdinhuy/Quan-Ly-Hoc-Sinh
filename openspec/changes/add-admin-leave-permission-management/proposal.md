# Add Admin Web Leave Permission Management Screen

## Why
Admins currently lack a centralized web interface to manage all leave permissions across the school. While teachers can approve requests via `duyet_ve_phep_screen.dart`, admins need a comprehensive management view with:
- Ability to filter by class (similar to entry/exit management)
- Three status tabs: Pending, Approved, Rejected
- Full CRUD operations (create, edit, delete)
- Approval/rejection capabilities
- Overview of all requests regardless of source (student, parent, teacher-entered)

The existing `ra_vao_screen.dart` provides the ideal pattern for this admin interface.

## What Changes
- Create new admin web screen: `ve_phep_admin_screen.dart` following the `ra_vao_screen.dart` pattern
- Add three tabs with TabController: "Chờ Duyệt", "Đã Duyệt", "Từ Chối"
- Add class dropdown filter to view leave permissions by class
- Add "Thêm Yêu Cầu" button to manually create leave permissions (opens existing `GiaoVienNhapVePhepFormDialog`)
- Display requests in DataTable with columns: Student, Card, Dates, Guardian, Reason, Source, Actions
- Add approve/reject buttons for pending requests
- Add edit/delete buttons for all requests
- Reuse existing `XinVePhepService` methods and detail dialog

## Impact
- **Affected specs**:
  - admin-management (new capability for admin web interface)
- **Affected code**:
  - `lib/screens/ve_phep_admin_screen.dart` (new file)
  - Admin navigation/menu (to add link to new screen)
- **Dependencies**:
  - Reuses `XinVePhepService` (already has all CRUD methods)
  - Reuses `GiaoVienNhapVePhepFormDialog` for create/edit
  - Reuses `XinVePhepDetailDialog` for view details
  - Reuses `LopService` for class dropdown
- **Breaking changes**: None

