# Tasks: Add Student Leave Permission System (Xin Về Phép)

**Note:** This creates a completely NEW system separate from the existing `xin_ra_vao` system. All tasks are additions, not modifications to existing code.

## Phase 1: Core Data Model & Validation

### Task 1.1: Create XinVePhep model
- Create new file `lib/models/xin_ve_phep.dart`
- Define `TrangThaiVePhep` enum with values: `choDuyet`, `daDuyet`, `daVeTruong`, `tuChoi`
- Define `NguonVePhep` enum with values: `appHocSinh`, `appPhuHuynh`, `giaoVienNhap`
- Create `XinVePhep` class with all fields:
  - Student info: `idHocSinh`, `hoTenHocSinh`, `soTheHocSinh`, `idLop`, `tenLop`
  - Parent info (optional): `idPhuHuynh`, `tenPhuHuynh`
  - Leave details: `lyDo`, `thoiGianXinVe`, `ngayXinVe`, `thoiGianXuongTruong`, `ngayXuongTruong`
  - Guardian info: `tenNguoiDon`, `cccdNguoiDon`, `sdtNguoiDon`
  - Meal deduction: `danhSachNgayCatCom` (List<DateTime>)
  - Approval tracking: `idNguoiDuyet`, `tenNguoiDuyet`, `thoiGianDuyet`
  - Metadata: `trangThai`, `nguon`, `lyDoTuChoi`, `createdAt`, `updatedAt`
- Implement `fromFirestore()` factory method with proper null handling
- Implement `toFirestore()` method with correct field mapping (snake_case)
- Implement `copyWith()` method for all fields
- **Validation**: Model compiles, all fields serialize/deserialize correctly

### Task 1.2: Create validation utilities
- Create new file `lib/utils/validation_utils.dart` (if doesn't exist, otherwise add to existing)
- Add `isValidCCCD(String cccd)` - validates exactly 12 digits
- Add `isValidVietnamesePhone(String phone)` - validates Vietnamese phone format (0xxxxxxxxx or +84xxxxxxxxx)
- Add `calculateMealDays(DateTime leave, DateTime? return)` - calculates days between dates
- Add `generateMealDeductionDates(DateTime leave, DateTime? return)` - generates list of dates for meal deduction
- Add `isValidMealDeductionDate(DateTime date, DateTime leave, DateTime? return)` - validates date is within leave period
- **Validation**: Unit tests pass for all validators (create test file if needed)

## Phase 2: Service Layer

### Task 2.1: Create XinVePhepService
- Create new file `lib/services/xin_ve_phep_service.dart`
- Define collection constant: `static const String collection = 'xin_ve_phep';`
- Implement CRUD operations:
  - `createXinVePhep(XinVePhep xin)` → returns document ID
  - `updateXinVePhep(String id, XinVePhep xin)`
  - `deleteXinVePhep(String id)`
  - `getXinVePhepById(String id)` → returns `XinVePhep?`
- Implement query methods:
  - `getXinVePhepByHocSinh(String idHocSinh)` → ordered by `created_at desc`
  - `getXinVePhepByLop(String idLop)` → ordered by `created_at desc`
  - `getXinVePhepByTrangThai(TrangThaiVePhep trangThai)` → ordered by `created_at desc`
- Implement streams:
  - `streamXinVePhepByHocSinh(String idHocSinh)`
  - `streamPendingApprovals()` → filters `trangThai == choDuyet`
  - `streamPendingForTeacher(String idLop)` → filters `trangThai == choDuyet AND idLop == $idLop`
- Implement approval action methods:
  - `approve(String id, String teacherId, String teacherName)` → updates status to `daDuyet`
  - `reject(String id, String reason, String teacherId)` → updates status to `tuChoi`
  - `markReturned(String id, DateTime returnTime)` → updates status to `daVeTruong`
- **Validation**: Service methods work with Firebase, no errors in CRUD operations

## Phase 3: Student/Parent Screens

### Task 3.1: Create student leave permission request screen
- Create new directory `lib/screens/hoc_sinh/xin_ve_phep/`
- Create new file `dang_ky_ve_phep_screen.dart`
- Build form with sections:
  1. **Student Info Card** (read-only, auto-filled from LocalDataService)
     - Display: `hoTen`, `soTheHocSinh`, `idLop`
  2. **Leave Dates & Times Card**
     - Date picker for `ngayXinVe` (leave start date)
     - Time picker for `thoiGianXinVe` (leave start time)
     - Date picker for `ngayXuongTruong` (return date, optional)
     - Time picker for `thoiGianXuongTruong` (return time, optional)
  3. **Guardian Information Card** (NEW)
     - Text field for `tenNguoiDon` (required, min 3 chars)
     - Text field for `cccdNguoiDon` (required, 12 digits, number keyboard)
     - Text field for `sdtNguoiDon` (required, phone format, phone keyboard)
     - All fields validated using `validation_utils.dart`
  4. **Meal Deduction Date Selection Card**
     - Auto-generates list of dates between leave start and return dates
     - Display dates as checkboxes or calendar with selectable dates
     - Default: All dates selected (full meal deduction)
     - Allow select/deselect individual dates
     - Show count: "Đã chọn X ngày cắt cơm"
     - Store selected dates in `danhSachNgayCatCom` list
     - Updates when leave dates change
  5. **Reason Card**
     - Multi-line text field for `lyDo` (required, min 10 chars)
- Implement submit logic:
  - Validate all fields
  - Fetch student & class info to populate `idHocSinh`, `hoTenHocSinh`, `idLop`, `tenLop`
  - Set `idPhuHuynh` = null and `tenPhuHuynh` = null (student submission)
  - Create `XinVePhep` object with `nguon = NguonVePhep.appHocSinh`
  - Call `XinVePhepService.createXinVePhep()`
  - Show success snackbar and navigate back
- **Validation**: Screen displays correctly, form validation works, submission creates Firestore record

### Task 3.2: Create student leave permission history screen
- Create new file `lib/screens/hoc_sinh/xin_ve_phep/lich_su_ve_phep_screen.dart`
- Use `StreamBuilder` with `XinVePhepService.streamXinVePhepByHocSinh()`
- Display list of leave permissions with cards showing:
  - Leave dates (start/return)
  - Status badge with color coding
  - Guardian name
  - Meal deduction dates count and list
  - Approval chain (if approved)
- Add filter by status (dropdown)
- Tap card to show detail dialog
- **Validation**: List displays real-time updates, status badges show correct colors

### Task 3.3: Create parent leave permission request screen
- Create new directory `lib/screens/phu_huynh/xin_ve_phep/`
- Create new file `dang_ky_ve_phep_phu_huynh_screen.dart`
- Similar to Task 3.1 but:
  - Add dropdown to select child (if parent has multiple children)
  - Fetch children using `PhuHuynhService` and `HocSinhService`
  - Pre-fill guardian info from parent's profile (name, CCCD, phone)
  - Fetch parent info from `LocalDataService` to populate `idPhuHuynh` and `tenPhuHuynh`
  - Set `nguon = NguonVePhep.appPhuHuynh`
  - Include parent ID and name in submission for audit trail
- **Validation**: Parent can select child, form works as expected, parent info is saved

### Task 3.4: Create parent leave permission history screen
- Create new file `lib/screens/phu_huynh/xin_ve_phep/lich_su_ve_phep_phu_huynh_screen.dart`
- Show leave permissions for all parent's children
- Group by child or show flat list with child name
- Similar display to Task 3.2
- **Validation**: Shows permissions for all children correctly

## Phase 4: Teacher Approval Screen

### Task 4.1: Create teacher approval screen
- Create new directory `lib/screens/giao_vien/duyet_ve_phep/`
- Create new file `duyet_ve_phep_screen.dart`
- Check teacher assignments:
  - If teacher is duty teacher (check `phan_cong_truc_ban`): Use `XinVePhepService.streamPendingApprovals()` to show ALL pending requests
  - If teacher is homeroom teacher (check `phan_cong_chu_nhiem`): Use `XinVePhepService.streamPendingForTeacher(idLop)` to show only their class requests
- Use `StreamBuilder` with appropriate stream based on teacher role
- Display list of requests with status `choDuyet`
- Each card shows:
  - Student name, class, card number
  - Leave dates (start/return)
  - Guardian info (name, CCCD, phone)
  - Meal deduction dates count and list
  - Reason for leave
- Tap card to show detail dialog with actions:
  - **Approve button** → calls `XinVePhepService.approve()`
  - **Reject button** → shows dialog to enter reason, calls `XinVePhepService.reject()`
- Add date filter (today, this week, all)
- Add class filter (for duty teachers who see all classes)
- **Validation**: Shows correct requests based on teacher role, approval/rejection updates status correctly

### Task 4.2: Create leave permission detail dialog
- Create new file `lib/widgets/xin_ve_phep_detail_dialog.dart`
- Reusable dialog widget accepting `XinVePhep` object
- Display all fields in organized sections:
  1. Student info
  2. Request source info:
     - If `nguon == appPhuHuynh` and `tenPhuHuynh` is not null: Show "Phụ huynh: [name]"
     - If `nguon == appHocSinh`: Show "Học sinh tự nộp"
     - If `nguon == giaoVienNhap`: Show "Giáo viên nhập"
  3. Leave dates/times
  4. Guardian information (highlighted)
  5. Meal deduction dates list (count + specific dates)
  6. Reason
  7. Approval history (timeline style):
     - Created at timestamp
     - Teacher approval (if exists) - show `tenNguoiDuyet` and `thoiGianDuyet`
     - Rejection info (if rejected)
- **Validation**: Dialog displays all information clearly and formatted correctly

## Phase 5: Navigation Integration

### Task 5.1: Add menu items to student main screen
- Open `lib/screens/hoc_sinh/main/main_hoc_sinh.dart`
- Add new menu card or list item: "Xin Về Phép"
- Navigate to `DangKyVePhepScreen`
- Add new menu card or list item: "Lịch Sử Về Phép"
- Navigate to `LichSuVePhepScreen`
- **Validation**: Menu items appear, navigation works

### Task 5.2: Add menu items to parent main screen
- Open `lib/screens/phu_huynh/main_phu_huynh/main_phu_huynh_screen.dart`
- Add new menu card: "Xin Về Phép Cho Con"
- Navigate to `DangKyVePhepPhuHuynhScreen`
- Add new menu card: "Lịch Sử Về Phép"
- Navigate to `LichSuVePhepPhuHuynhScreen`
- **Validation**: Menu items appear, navigation works

### Task 5.3: Add menu item to teacher main screen
- Open `lib/screens/giao_vien/main_giao_vien/main_giao_vien_screen.dart`
- Add new menu card: "Duyệt Về Phép"
- Navigate to `DuyetVePhepScreen`
- Menu item available to all teachers (both duty and homeroom)
- **Validation**: Menu item appears, navigation works

## Phase 6: Testing & Polish

### Task 6.1: End-to-end workflow testing
- Test complete flow 1: Student submit → Teacher approve → Status `daDuyet`
- Test complete flow 2: Parent submit → Teacher reject → Status `tuChoi`
- Test complete flow 3: Student submit → Duty teacher approves (from all classes view)
- Test complete flow 4: Student submit → Homeroom teacher approves (from their class view)
- Test edge case: Student with no return date (optional field handling)
- Test edge case: Partial meal deduction date selection (select only some dates)
- **Validation**: All workflows complete successfully without errors

### Task 6.2: Validation testing
- Test CCCD validation: only accepts 12 digits, rejects letters/symbols
- Test phone validation: accepts Vietnamese formats, rejects invalid formats
- Test meal deduction date generation: correct dates generated for date range
- Test meal deduction date validation: only dates within leave period are selectable
- Test empty meal deduction list: system accepts empty array
- Test meal deduction date selection UI: can select/deselect individual dates
- Test required fields: all marked fields cannot be empty
- **Validation**: All validations work with clear Vietnamese error messages

### Task 6.3: Permission and role testing
- Test teacher approval screen as duty teacher: shows all pending requests from all classes
- Test teacher approval screen as homeroom teacher: shows only requests from their class
- Test student screens: only accessible by students, shows only their requests
- Test parent screens: only accessible by parents, shows only their children's requests
- **Validation**: Proper authorization, no data leakage between roles

### Task 6.4: Real-time updates testing
- Open teacher approval screen, submit request from student app → verify appears immediately
- Open student history, approve as teacher → verify status updates immediately
- Test with multiple teachers viewing same requests → all see real-time updates
- **Validation**: All streams work correctly with real-time Firebase updates

### Task 6.5: UI/UX polish
- Verify consistent card styling across all screens
- Verify status badge colors are distinct and meaningful
- Verify Vietnamese text is grammatically correct
- Verify date/time formatting is consistent (dd/MM/yyyy HH:mm)
- Add loading states for all async operations
- Add empty states ("Chưa có yêu cầu") when lists are empty
- Verify responsive layout works on both web and mobile
- **Validation**: UI is polished, consistent, and user-friendly

### Task 6.6: Firestore indexes
- Create composite index: `trang_thai` + `created_at DESC`
- Create composite index: `trang_thai` + `id_lop` + `created_at DESC`
- Create composite index: `id_hoc_sinh` + `created_at DESC`
- Test queries run without Firestore index errors
- **Validation**: All queries execute efficiently without missing index warnings

## Phase 7: Documentation & Cleanup

### Task 7.1: Update CLAUDE.md
- Add section for new `xin_ve_phep` system
- Document the distinction between `xin_ra_vao` and `xin_ve_phep`
- Document new model, service, and screens
- Update Firebase collections list
- **Validation**: Documentation is clear and accurate

### Task 7.2: Code cleanup
- Remove any unused imports
- Run `dart format lib/`
- Run `flutter analyze` and fix any warnings
- Verify no console debug prints remain
- **Validation**: Code is clean and follows project conventions

## Dependency Graph

```
Phase 1 (Model & Validation)
  ↓
Phase 2 (Service Layer)
  ↓
Phase 3 (Student/Parent Screens) ←→ Phase 4 (Teacher Screens)
  ↓                                        ↓
Phase 5 (Navigation) ← - - - - - - - - - ┘
  ↓
Phase 6 (Testing & Polish)
  ↓
Phase 7 (Documentation)
```

**Parallelizable:**
- Phase 3 and Phase 4 can be worked on simultaneously after Phase 2
- Task 3.1-3.4 can be split among developers
- Task 4.1-4.2 can be split among developers

## Estimated Effort

- Phase 1: 1.5 hours
- Phase 2: 1.5 hours
- Phase 3: 3 hours
- Phase 4: 2 hours (reduced - single screen instead of two)
- Phase 5: 30 minutes
- Phase 6: 2 hours
- Phase 7: 30 minutes

**Total: ~11 hours**

## Critical Notes

1. **Do NOT modify existing `xin_ra_vao` system** - this is completely separate
2. **All fields are in snake_case in Firestore** - double check field mapping
3. **Status enum values are camelCase in Dart, snake_case in Firestore** - use proper conversion
4. **Guardian info is required** - all three fields (name, CCCD, phone) must be validated
5. **Single-level approval** - any authorized teacher (duty or homeroom) can approve, only ONE approval needed
6. **Real-time streams** - use `StreamBuilder` for live updates, remember to dispose
7. **Firestore indexes** - create before testing to avoid slow queries
8. **Vietnamese text** - double-check all UI strings for grammatical correctness
9. **Role-based filtering** - duty teachers see all requests, homeroom teachers see only their class
