# Implementation Tasks

## Overview
Add teacher/admin web entry and parent mobile app request flows for the leave permission system. Both flows reuse the existing `XinVePhep` model, `XinVePhepService`, and validation utilities.

## Phase 1: Parent Mobile App Request Flow

### Task 1.1: Create parent leave permission request screen
- **File**: `lib/screens/phu_huynh/xin_ve_phep/dang_ky_ve_phep_phu_huynh_screen.dart`
- **Description**: Create form screen for parents to request leave for their child
- **Details**:
  - Extend StatefulWidget pattern similar to student request screen
  - Auto-load child information from `PhuHuynh.idHs` using `HocSinhService.getHocSinhById()`
  - Auto-load parent information from `LocalDataService.getId()` using `PhuHuynhService.getPhuHuynhById()`
  - Auto-fill student section (read-only): name, card number, class
  - Auto-fill guardian section (editable): name from `hoTen`, CCCD from `soCccd`, phone from `soDienThoai`
  - Date/time pickers for leave and return dates (same as student screen)
  - Meal deduction date selection using FilterChip (reuse logic from student screen)
  - Multi-line text field for reason
  - Submit button that creates `XinVePhep` with `nguon: NguonVePhep.appPhuHuynh` and `tenPhuHuynh: parent.hoTen`
- **Validation**:
  - Use existing `isValidCCCD()` and `isValidVietnamesePhone()` from `validation_utils.dart`
  - Ensure leave date is not in the past
  - Return date must be after leave date if provided
  - At least one meal deduction date selected if return date is provided
  - Reason field required with minimum 10 characters
- **Dependencies**: None (can start immediately)

### Task 1.2: Create parent leave permission history screen
- **File**: `lib/screens/phu_huynh/xin_ve_phep/lich_su_ve_phep_phu_huynh_screen.dart`
- **Description**: Create history view for parents to see all leave requests for their child
- **Details**:
  - Similar to student history screen but query by `idHocSinh` (parent's child)
  - Use `StreamBuilder` with `XinVePhepService.streamXinVePhepByHocSinh(childId)`
  - Display all requests regardless of source (student, parent, or teacher-entered)
  - Show source indicator on each card
  - Filter dropdown for status (all, pending, approved, rejected, returned)
  - Tap card to open `XinVePhepDetailDialog`
  - Pull-to-refresh support
- **Dependencies**: None (can start in parallel with 1.1)

### Task 1.3: Add navigation to parent main screen
- **File**: `lib/screens/phu_huynh/main_phu_huynh/main_phu_huynh_screen.dart`
- **Description**: Add two new action cards to parent main menu
- **Details**:
  - Add "Xin Về Phép" action card with orange color scheme and time_to_leave icon
  - Add "Lịch Sử Về Phép" action card with orange/brown color and event_note icon
  - Place after existing "Lịch sử ra vào của con" action (around line 337)
  - Navigate to `DangKyVePhepPhuHuynhScreen` and `LichSuVePhepPhuHuynhScreen` respectively
- **Dependencies**: Tasks 1.1 and 1.2 must be complete

### Task 1.4: Update detail dialog to show parent source
- **File**: `lib/widgets/xin_ve_phep_detail_dialog.dart`
- **Description**: Ensure detail dialog correctly displays parent as source
- **Details**:
  - The `_buildSourceInfoSection()` method already handles `NguonVePhep.appPhuHuynh`
  - Verify it displays "Phụ huynh: [name]" when `tenPhuHuynh` is not null
  - Verify it displays just "Phụ huynh" when `tenPhuHuynh` is null
  - Test with parent-submitted requests
- **Dependencies**: Task 1.1 must be complete for testing

## Phase 2: Teacher/Admin Web Entry Flow

### Task 2.1: Create teacher/admin leave permission entry dialog
- **File**: `lib/widgets/giao_vien_nhap_ve_phep_form_dialog.dart`
- **Description**: Create form dialog for teachers to manually create leave permissions
- **Details**:
  - Create as a Dialog widget (similar to other `_form_dialog.dart` files)
  - Student search section:
    - TextField for card number or name search
    - Search button that queries `HocSinhService`
    - Display selected student info (name, card, class, photo if available)
    - Clear/reset button to select different student
  - Guardian info section (manual entry, same validation as other forms):
    - Name, CCCD, phone number fields
    - Validation using `validation_utils.dart` functions
  - Leave dates section:
    - DatePickers for leave date and return date
    - TimePickers for leave time and return time
  - Meal deduction section:
    - Auto-generate dates from leave/return range
    - FilterChip selection (same as student/parent forms)
  - Reason section:
    - Multi-line text field with validation
  - Pre-approval option:
    - Checkbox: "Duyệt luôn (Pre-approve)"
    - If checked, create with status `daDuyet` and set approver to current teacher
    - If unchecked, create with status `choDuyet`
  - Submit creates `XinVePhep` with `nguon: NguonVePhep.giaoVienNhap`
- **Validation**: Same as student/parent forms plus student selection required
- **Dependencies**: None (can start in parallel with Phase 1)

### Task 2.2: Add navigation from admin/teacher web interface
- **File**: Determine best location (possibly `lib/screens/admin_management_screen.dart` or dedicated admin leave management screen)
- **Description**: Add button/menu item to access teacher leave permission entry
- **Details**:
  - Option A: Add to existing admin management screen as a new section
  - Option B: Create dedicated "Leave Permission Management" screen accessed from admin menu
  - Option C: Add to teacher approval screen as "Create New" button
  - **Recommended**: Option C - add "Tạo mới" (Create New) button to `duyet_ve_phep_screen.dart` AppBar
  - Button should be visible to all teachers (they may need to enter on behalf of students)
  - Tap opens `GiaoVienNhapVePhepFormDialog`
- **Dependencies**: Task 2.1 must be complete

### Task 2.3: Update detail dialog to show teacher entry source
- **File**: `lib/widgets/xin_ve_phep_detail_dialog.dart`
- **Description**: Ensure detail dialog correctly displays teacher entry as source
- **Details**:
  - The `_buildSourceInfoSection()` method already handles `NguonVePhep.giaoVienNhap`
  - Verify it displays "Giáo viên nhập"
  - Consider adding teacher name if available (may need to add `tenGiaoVienNhap` field to model - OUT OF SCOPE for now)
  - Test with teacher-entered requests
- **Dependencies**: Task 2.1 must be complete for testing

## Phase 3: Testing & Documentation

### Task 3.1: Test parent flow end-to-end
- **Description**: Verify complete parent request workflow
- **Test scenarios**:
  - Parent submits leave request with auto-filled guardian info
  - Parent modifies phone number before submission
  - Parent views history showing mix of student and parent requests
  - Teacher approves parent-submitted request
  - Request appears correctly in all views with proper source labeling
  - Validation prevents invalid CCCD/phone submission
- **Dependencies**: Phase 1 complete

### Task 3.2: Test teacher entry flow end-to-end
- **Description**: Verify complete teacher manual entry workflow
- **Test scenarios**:
  - Teacher searches for student by card number
  - Teacher searches for student by name
  - Teacher creates leave permission without pre-approval (goes to queue)
  - Teacher creates leave permission WITH pre-approval (bypasses queue)
  - Pre-approved requests show teacher as approver
  - Request appears correctly in all views with proper source labeling
  - Validation prevents invalid data submission
- **Dependencies**: Phase 2 complete

### Task 3.3: Update CLAUDE.md documentation
- **File**: `CLAUDE.md`
- **Description**: Update leave permission system documentation
- **Details**:
  - Add parent request flow to "Request submission" section
  - Add teacher entry flow to "Request submission" section
  - Update "Related files" section with new screen paths
  - Document pre-approval option for teacher entry
  - Note that all three sources use same approval workflow (unless pre-approved)
- **Dependencies**: All implementation complete

### Task 3.4: Code cleanup
- **Description**: Final cleanup and formatting
- **Details**:
  - Run `dart format lib/screens/phu_huynh/xin_ve_phep/ lib/widgets/giao_vien_nhap_ve_phep_form_dialog.dart`
  - Remove any TODO comments
  - Remove debug print statements
  - Verify no unused imports
- **Dependencies**: All implementation complete

## Implementation Notes

### Reusable Components
- Validation functions from `lib/utils/validation_utils.dart`
- Service methods from `lib/services/xin_ve_phep_service.dart`
- Detail dialog from `lib/widgets/xin_ve_phep_detail_dialog.dart`
- Existing date range and meal deduction logic patterns

### Key Differences by Flow

**Student Flow** (existing):
- Source: `NguonVePhep.appHocSinh`
- Guardian info: Manual entry
- Student info: Auto-filled from logged-in student
- Always requires approval

**Parent Flow** (new):
- Source: `NguonVePhep.appPhuHuynh`
- Guardian info: Auto-filled from `PhuHuynh` profile (editable)
- Student info: Auto-filled from parent's linked child
- Parent name stored in `tenPhuHuynh`
- Always requires approval

**Teacher Entry** (new):
- Source: `NguonVePhep.giaoVienNhap`
- Guardian info: Manual entry
- Student info: Search and select
- Optional pre-approval to bypass queue
- Useful for phone/paper form transcription

### Estimated Timeline
- Phase 1 (Parent flow): 2-3 hours
- Phase 2 (Teacher flow): 2-3 hours
- Phase 3 (Testing & docs): 1 hour
- **Total**: 5-7 hours

### Parallel Work Opportunities
- Tasks 1.1 and 1.2 can be developed in parallel
- Task 2.1 can be developed while Phase 1 is in progress
- All three flows are independent and can be implemented by different developers if needed
