# Admin Leave Permission Management

## ADDED Requirements

### Requirement: Admins shall be able to manage all leave permissions via web interface

Admins accessing the web interface SHALL be able to view, create, approve, reject, edit, and delete leave permission requests for all students across all classes.

#### Scenario: Admin views leave permissions by class and status

**Given** an admin is logged into the web interface
**When** they navigate to the leave permission management screen
**Then** they should see a class dropdown filter
**And** they should see three tabs: "Chờ Duyệt" (Pending), "Đã Duyệt" (Approved), "Từ Chối" (Rejected)
**And** requests should be displayed in a DataTable

**When** they select a class from the dropdown
**Then** only leave permissions for students in that class should be displayed
**And** requests should be filtered by the active tab status

#### Scenario: Admin creates new leave permission

**Given** an admin is on the leave permission management screen
**And** a class is selected
**When** they click the "Thêm Yêu Cầu" (Add Request) button
**Then** the teacher manual entry dialog (`GiaoVienNhapVePhepFormDialog`) should open
**And** they can search for a student and create a leave permission
**And** upon successful creation, the request should appear in the appropriate tab

#### Scenario: Admin approves pending leave permission

**Given** an admin is viewing the "Chờ Duyệt" (Pending) tab
**And** there are pending leave permission requests displayed
**When** they click the approve icon (green checkmark) for a request
**Then** a confirmation dialog should appear
**And** upon confirmation, the request status should be updated to `daDuyet` (Approved)
**And** the admin's ID and name should be recorded as the approver
**And** the request should move to the "Đã Duyệt" tab

#### Scenario: Admin rejects pending leave permission

**Given** an admin is viewing the "Chờ Duyệt" (Pending) tab
**And** there are pending leave permission requests displayed
**When** they click the reject icon (red X) for a request
**Then** a dialog should prompt for rejection reason
**And** upon providing a reason and confirming, the request status should be updated to `tuChoi` (Rejected)
**And** the rejection reason should be stored
**And** the request should move to the "Từ Chối" tab

#### Scenario: Admin edits existing leave permission

**Given** an admin is viewing any tab (Pending, Approved, or Rejected)
**When** they click the edit icon (blue pencil) for a request
**Then** the teacher manual entry dialog should open pre-filled with the request data
**And** they can modify any fields (student, dates, guardian info, reason)
**And** upon saving, the request should be updated in Firestore
**And** the table should refresh to show the updated data

#### Scenario: Admin deletes leave permission

**Given** an admin is viewing any tab
**When** they click the delete icon (red trash) for a request
**Then** a confirmation dialog should appear
**And** upon confirmation, the request should be deleted from Firestore
**And** the request should be removed from the table

#### Scenario: Admin views requests from all sources

**Given** an admin is viewing the leave permission management screen
**Then** requests created by students (source: `appHocSinh`) should be displayed
**And** requests created by parents (source: `appPhuHuynh`) should be displayed
**And** requests manually entered by teachers (source: `giaoVienNhap`) should be displayed
**And** each request should show its source in the "Nguồn" column

#### Scenario: DataTable displays comprehensive request information

**Given** an admin is viewing any tab with leave permission requests
**Then** the DataTable should display the following columns:
  - Học Sinh (Student name)
  - Số Thẻ (Card number)
  - Ngày về (Leave date)
  - Ngày xuống trường (Return date)
  - Người đón (Guardian name)
  - Lý do (Reason, truncated if long)
  - Nguồn (Source: student/parent/teacher)
  - Thao Tác (Action buttons)

**And** each row should display one leave permission request
**And** long text fields should be truncated with ellipsis

### Requirement: Admin leave permission management shall follow the entry/exit screen pattern

The leave permission admin screen SHALL follow the same UI/UX pattern as the entry/exit management screen (`ra_vao_screen.dart`) for consistency.

#### Scenario: Screen layout matches entry/exit screen pattern

**Given** an admin is viewing the leave permission management screen
**Then** the screen layout should include:
  - Page title "Quản Lý Về Phép" at the top
  - Class dropdown and "Thêm Yêu Cầu" button in a horizontal row
  - TabBar with 3 tabs (Pending, Approved, Rejected)
  - TabBarView with DataTable for each tab
  - Loading spinner when data is being fetched

**And** the visual design should match `ra_vao_screen.dart` styling

#### Scenario: Tab icons and labels match conventions

**Given** an admin is viewing the tabs
**Then** the "Chờ Duyệt" tab should have a pending icon
**And** the "Đã Duyệt" tab should have a check icon
**And** the "Từ Chối" tab should have a cancel icon
**And** tab labels should be in Vietnamese

## MODIFIED Requirements

None - This is a new admin interface that complements existing screens without modifying them.

## REMOVED Requirements

None

