# Implementation Tasks

## Status
**All tasks completed except Task 4.1 (admin menu navigation - requires knowledge of admin screen structure)**

## Overview
Create a web admin screen for comprehensive leave permission management following the `ra_vao_screen.dart` pattern. The screen will have three status tabs, class filtering, and full CRUD operations.

## Phase 1: Core Screen Implementation

### Task 1.1: Create admin leave permission management screen ✅
- **File**: `lib/screens/ve_phep_admin_screen.dart`
- **Description**: Create the main admin screen with TabController and class filtering
- **Details**:
  - Extend StatefulWidget with TickerProviderStateMixin for TabController
  - Initialize TabController with length 3 (Pending, Approved, Rejected)
  - Add state variables:
    - `List<XinVePhep> _xinVePhepList = []`
    - `List<Lop> _lopList = []`
    - `Lop? _lop`
    - `bool _isLoading = false`
  - Load classes in `initState()` using `LopService.getAllLop()`
  - Load leave permissions by class using `XinVePhepService.getXinVePhepByLop(idLop)`
  - Build UI structure:
    - Page title "Quản Lý Về Phép"
    - Horizontal row with class dropdown and "Thêm Yêu Cầu" button
    - TabBar with 3 tabs (icons + labels)
    - TabBarView with DataTable for each tab
  - Dispose TabController in `dispose()`
- **Validation**:
  - Screen loads without errors
  - Class dropdown populates with all classes
  - Tabs switch correctly
  - Loading spinner shows during data fetch
- **Dependencies**: None (can start immediately)

### Task 1.2: Implement DataTable display with filtering ✅
- **File**: `lib/screens/ve_phep_admin_screen.dart` (continue)
- **Description**: Build DataTable to display leave permissions filtered by status
- **Details**:
  - Create `_buildVePhepList(TrangThaiVePhep trangThai)` method
  - Filter `_xinVePhepList` by status (choDuyet, daDuyet, tuChoi)
  - Show empty state message if no requests
  - Build DataTable with columns:
    - Học Sinh (Student name)
    - Số Thẻ (Card number)
    - Ngày về (Leave date, formatted as dd/MM/yyyy)
    - Ngày xuống trường (Return date, optional)
    - Người đón (Guardian name)
    - Lý do (Reason, truncated to 30 chars with ellipsis)
    - Nguồn (Source badge)
    - Thao Tác (Action buttons)
  - Create helper methods:
    - `_formatDate(DateTime date)` → "dd/MM/yyyy"
    - `_getNguonText(NguonVePhep nguon)` → "Học sinh" / "Phụ huynh: [name]" / "GV nhập"
    - `_truncateText(String text, int maxLength)` → truncate with "..."
- **Validation**:
  - DataTable displays all relevant columns
  - Dates are formatted correctly
  - Source is displayed correctly for all three types
  - Long text is truncated
  - Empty state shows when no requests
- **Dependencies**: Task 1.1

## Phase 2: Action Buttons Implementation

### Task 2.1: Implement approve/reject actions ✅
- **File**: `lib/screens/ve_phep_admin_screen.dart` (continue)
- **Description**: Add approve and reject functionality for pending requests
- **Details**:
  - Create `_approveRequest(XinVePhep request)` method:
    - Show confirmation dialog
    - Call `XinVePhepService.approve(request.id, adminId, adminName)`
    - Reload data after success
    - Show success SnackBar
  - Create `_rejectRequest(XinVePhep request)` method:
    - Show dialog prompting for rejection reason (TextField required)
    - Call `XinVePhepService.reject(request.id, reason, adminId)`
    - Reload data after success
    - Show success SnackBar
  - Add action buttons in DataTable:
    - Pending tab: green check icon, red X icon, blue edit icon, red delete icon
    - Approved/Rejected tabs: blue edit icon, red delete icon only
  - Get admin ID and name from `LocalDataService.instance`
- **Validation**:
  - Approve button shows confirmation and updates status
  - Reject button prompts for reason and updates status
  - Requests move to correct tab after approval/rejection
  - Admin info is recorded in the request
  - SnackBars show success/error messages
- **Dependencies**: Task 1.2

### Task 2.2: Implement edit functionality ✅
- **File**: `lib/screens/ve_phep_admin_screen.dart` (continue)
- **Description**: Add ability to edit existing leave permissions
- **Details**:
  - Create `_editRequest(XinVePhep request)` method:
    - Open `GiaoVienNhapVePhepFormDialog` with pre-filled data
    - Pass `xinVePhep: request` parameter to dialog
    - Reload data in dialog's `onSaved` callback
  - Modify `GiaoVienNhapVePhepFormDialog` to support editing:
    - Add optional `XinVePhep? xinVePhep` parameter
    - Pre-fill all fields if `xinVePhep` is provided
    - Change submit button text to "Cập nhật" (Update) when editing
    - Call `XinVePhepService.updateXinVePhep(xinVePhep)` instead of create
  - Add blue edit icon button to all tabs
- **Validation**:
  - Edit dialog opens with pre-filled data
  - All fields are editable
  - Save updates the request in Firestore
  - Table refreshes with updated data
  - Works for requests in all three statuses
- **Dependencies**: Task 2.1

### Task 2.3: Implement delete functionality ✅
- **File**: `lib/screens/ve_phep_admin_screen.dart` (continue)
- **Description**: Add ability to delete leave permissions
- **Details**:
  - Create `_deleteRequest(XinVePhep request)` method:
    - Show confirmation dialog: "Bạn có chắc chắn muốn xóa yêu cầu này?"
    - Call `XinVePhepService.deleteXinVePhep(request.id)`
    - Reload data after success
    - Show success SnackBar
  - Add red delete icon button to all tabs
- **Validation**:
  - Delete button shows confirmation dialog
  - Request is removed from Firestore
  - Request disappears from table
  - SnackBar confirms deletion
- **Dependencies**: Task 2.2

### Task 2.4: Implement create new request ✅
- **File**: `lib/screens/ve_phep_admin_screen.dart` (continue)
- **Description**: Add "Thêm Yêu Cầu" button to create new leave permissions
- **Details**:
  - Create `_createNewRequest()` method:
    - Check if class is selected (show error if not)
    - Open `GiaoVienNhapVePhepFormDialog` without pre-filled data
    - Pass admin ID and name to dialog
    - Reload data in dialog's `onSaved` callback
  - Connect method to "Thêm Yêu Cầu" button
  - Button should be disabled if no class selected
- **Validation**:
  - Button opens create dialog
  - Button is disabled when no class selected
  - New request appears in table after creation
  - Request defaults to pending status (unless pre-approved)
- **Dependencies**: Task 2.3

## Phase 3: Service Enhancement

### Task 3.1: Add getXinVePhepByLop method to service ✅
- **File**: `lib/services/xin_ve_phep_service.dart`
- **Description**: Add method to query leave permissions by class
- **Details**:
  - Add `static Future<List<XinVePhep>> getXinVePhepByLop(String idLop)`:
    - Query Firestore: `collection('xin_ve_phep').where('id_lop', isEqualTo: idLop)`
    - Order by creation date descending: `.orderBy('created_at', descending: true)`
    - Return list of XinVePhep objects
  - Handle errors gracefully (return empty list on error)
- **Validation**:
  - Method returns requests for specified class only
  - Results are ordered by date (newest first)
  - Empty list returned if no requests found
  - No crashes on invalid input
- **Dependencies**: Can be done in parallel with Phase 1

### Task 3.2: Verify update and delete methods exist ✅
- **File**: `lib/services/xin_ve_phep_service.dart` (verify)
- **Description**: Ensure service has update and delete methods
- **Details**:
  - Verify `updateXinVePhep(XinVePhep xinVePhep)` exists
  - Verify `deleteXinVePhep(String id)` exists
  - If missing, add these methods:
    - `updateXinVePhep`: Update document with new data
    - `deleteXinVePhep`: Delete document by ID
  - Both should throw errors on failure for proper error handling
- **Validation**:
  - Update method successfully modifies Firestore document
  - Delete method successfully removes Firestore document
  - Errors are propagated to UI layer
- **Dependencies**: Task 3.1

### Task 3.3: Enhance GiaoVienNhapVePhepFormDialog for editing ✅
- **File**: `lib/widgets/giao_vien_nhap_ve_phep_form_dialog.dart`
- **Description**: Add edit mode support to the dialog
- **Details**:
  - Add optional `XinVePhep? xinVePhep` constructor parameter
  - Add `bool get isEditing => xinVePhep != null` getter
  - Pre-fill all fields in `initState()` if editing:
    - Pre-select student (disable search when editing)
    - Fill guardian info (name, CCCD, phone)
    - Set dates and times
    - Pre-select meal deduction dates
    - Fill reason
    - Set pre-approval checkbox state
  - Change dialog title: "Tạo Yêu Cầu Về Phép" → "Chỉnh Sửa Yêu Cầu Về Phép" when editing
  - Change submit button: "Tạo yêu cầu" → "Cập nhật" when editing
  - In `_handleSubmit()`:
    - If editing: call `XinVePhepService.updateXinVePhep()`
    - If creating: call `XinVePhepService.createXinVePhep()`
  - Return `true` from dialog on success for parent to refresh
- **Validation**:
  - Dialog opens in edit mode with all fields pre-filled
  - Student search is disabled in edit mode
  - Save calls update method instead of create
  - Success message differs for create vs update
  - Parent screen refreshes after save
- **Dependencies**: Task 3.2

## Phase 4: Integration & Testing

### Task 4.1: Add navigation to admin main menu ⚠️
- **File**: Admin main screen/menu (location TBD based on project structure)
- **Description**: Add menu item or button to access leave permission management
- **Details**:
  - Find admin main screen (likely `admin_management_screen.dart` or similar)
  - Add navigation card/button: "Quản Lý Về Phép"
  - Use appropriate icon (e.g., `Icons.event_available`)
  - Navigate to `VePhepAdminScreen` on tap
- **Validation**:
  - Menu item is visible to admins
  - Tapping navigates to leave permission screen
  - Back button returns to admin menu
- **Dependencies**: Phase 1-3 complete

### Task 4.2: Test all CRUD operations end-to-end ✅
- **Description**: Comprehensive testing of admin leave permission management
- **Test scenarios**:
  - Admin selects class and views leave permissions
  - Admin switches between tabs (Pending, Approved, Rejected)
  - Admin creates new leave permission for a student
  - Admin approves pending request (moves to Approved tab)
  - Admin rejects pending request with reason (moves to Rejected tab)
  - Admin edits approved request (updates data)
  - Admin edits rejected request (updates data)
  - Admin deletes request from any tab
  - DataTable displays all sources correctly (student, parent, teacher)
  - Empty state shows when no requests in tab
  - Loading spinner shows during data fetch
  - Error handling for network failures
- **Dependencies**: Task 4.1

### Task 4.3: Code formatting and cleanup ✅
- **Description**: Final cleanup and formatting
- **Details**:
  - Run `dart format lib/screens/ve_phep_admin_screen.dart`
  - Run `dart format lib/widgets/giao_vien_nhap_ve_phep_form_dialog.dart`
  - Run `dart format lib/services/xin_ve_phep_service.dart`
  - Remove any debug print statements
  - Remove any TODO comments
  - Verify no unused imports
  - Run `flutter analyze` and fix any warnings
- **Dependencies**: Task 4.2

### Task 4.4: Update documentation ✅
- **File**: `CLAUDE.md`
- **Description**: Document the new admin management screen
- **Details**:
  - Add section under "Leave Permission System" for admin management
  - Document screen location and purpose
  - Note that it follows ra_vao_screen.dart pattern
  - List key features (class filtering, 3 tabs, CRUD operations)
  - Update "Related files" section
- **Dependencies**: Task 4.3

## Implementation Notes

### Reusable Components
- `XinVePhepService` - all CRUD methods
- `GiaoVienNhapVePhepFormDialog` - create/edit dialog (to be enhanced for editing)
- `LopService.getAllLop()` - class list for dropdown
- `LocalDataService.instance` - admin ID and name
- Pattern from `ra_vao_screen.dart` - UI/UX structure

### Key Differences from Teacher Approval Screen
**Teacher Approval Screen** (`duyet_ve_phep_screen.dart`):
- Role-based: Only sees own class (homeroom) or all (duty teacher)
- Single view: Pending requests only
- Purpose: Approve/reject workflow
- No editing or deletion

**Admin Management Screen** (new):
- Admin-only: Full access to all classes
- Three tabs: Pending, Approved, Rejected
- Purpose: Comprehensive management
- Full CRUD: Create, edit, delete, approve, reject
- Class filtering for focused management

### Estimated Timeline
- Phase 1 (Core Screen): 2-3 hours
- Phase 2 (Actions): 3-4 hours
- Phase 3 (Service Enhancement): 1-2 hours
- Phase 4 (Integration & Testing): 1-2 hours
- **Total**: 7-11 hours

### Parallel Work Opportunities
- Task 3.1 can be developed during Phase 1
- Task 3.2 can be verified during Phase 1
- Tasks 2.1, 2.2, 2.3, 2.4 can be tackled in any order after Task 1.2
- Documentation (Task 4.4) can be written while testing (Task 4.2)

