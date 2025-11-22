# Design: Student Leave Permission System (Xin Về Phép)

## Architecture Overview

This design introduces a **completely new system** separate from the existing `xin_ra_vao` (temporary exit) system.

### System Separation

**Existing System: XinRaVao (Xin Ra Ngoài)**
- Purpose: Short-term temporary exits (a few hours)
- Use cases: Going home early, medical appointments
- Collection: `xin_ra_vao`
- **Status: Unchanged, remains as-is**

**New System: XinVePhep (Xin Về Phép)**
- Purpose: Formal leave permissions (one or more days)
- Use cases: Extended sick leave, family emergencies, holidays
- Collection: `xin_ve_phep` (NEW)
- **Status: Completely new implementation**

### Data Model - XinVePhep

#### New Model Definition
```dart
enum TrangThaiVePhep {
  choDuyet,           // Waiting for teacher approval (duty or homeroom)
  daDuyet,            // Approved by teacher
  daVeTruong,         // Student returned to school
  tuChoi,             // Rejected by teacher
}

enum NguonVePhep {
  appHocSinh,         // From student app
  appPhuHuynh,        // From parent app
  giaoVienNhap,       // Manually entered by teacher
}

class XinVePhep {
  // Identity & Basic Info
  final String? id;                      // Firestore document ID
  final String idHocSinh;                // Student ID
  final String hoTenHocSinh;             // Student full name
  final String soTheHocSinh;             // Student card number
  final String idLop;                    // Class ID
  final String tenLop;                   // Class name (denormalized)

  // Parent Information (NEW - optional, only if submitted by parent)
  final String? idPhuHuynh;              // Parent ID (null if submitted by student)
  final String? tenPhuHuynh;             // Parent full name

  // Leave Details
  final String lyDo;                     // Reason for leave
  final DateTime thoiGianXinVe;          // Leave start time & date
  final DateTime ngayXinVe;              // Leave start date (date only)
  final DateTime? thoiGianXuongTruong;   // Return time & date
  final DateTime? ngayXuongTruong;       // Return date (date only)

  // Guardian Pickup Information (NEW)
  final String tenNguoiDon;              // Guardian's full name
  final String cccdNguoiDon;             // Guardian's citizen ID (12 digits)
  final String sdtNguoiDon;              // Guardian's phone number

  // Meal Deduction (NEW)
  final List<DateTime> danhSachNgayCatCom;  // List of specific dates to deduct meals (date only, no time)

  // Single Approval (NEW)
  final String? idNguoiDuyet;            // Approver ID (teacher who approved)
  final String? tenNguoiDuyet;           // Approver name
  final DateTime? thoiGianDuyet;         // Approval timestamp

  // Status & Metadata
  final TrangThaiVePhep trangThai;       // Current approval status
  final NguonVePhep nguon;               // Request source
  final String? lyDoTuChoi;              // Rejection reason (if rejected)
  final DateTime createdAt;              // Request creation time
  final DateTime? updatedAt;             // Last update time

  XinVePhep({
    this.id,
    required this.idHocSinh,
    required this.hoTenHocSinh,
    required this.soTheHocSinh,
    required this.idLop,
    required this.tenLop,
    this.idPhuHuynh,
    this.tenPhuHuynh,
    required this.lyDo,
    required this.thoiGianXinVe,
    required this.ngayXinVe,
    this.thoiGianXuongTruong,
    this.ngayXuongTruong,
    required this.tenNguoiDon,
    required this.cccdNguoiDon,
    required this.sdtNguoiDon,
    this.danhSachNgayCatCom = const [],
    this.idNguoiDuyet,
    this.tenNguoiDuyet,
    this.thoiGianDuyet,
    this.trangThai = TrangThaiVePhep.choDuyet,
    required this.nguon,
    this.lyDoTuChoi,
    required this.createdAt,
    this.updatedAt,
  });

  // Standard methods: fromFirestore, toFirestore, copyWith
}
```

### Approval Workflow

```
[Student/Parent Submit]
        ↓
[choDuyet - Waiting for Teacher Approval]
        ↓
   (Teacher Approve) ────→ [daDuyet - Approved]
        ↓                           ↓
   (Teacher Reject)         (Student Returns)
        ↓                           ↓
   [tuChoi - Rejected]        [daVeTruong]
```

**Status Meanings:**
- `choDuyet`: Initial state, waiting for teacher approval (duty teacher or homeroom teacher)
- `daDuyet`: Approved by teacher, student can leave
- `daVeTruong`: Student has returned to school
- `tuChoi`: Rejected by teacher

### Database Schema (Firestore)

**New Collection: `xin_ve_phep`**

```javascript
{
  "id_hoc_sinh": string,
  "ho_ten_hoc_sinh": string,
  "so_the_hoc_sinh": string,
  "id_lop": string,
  "ten_lop": string,

  "id_phu_huynh": string | null,         // Parent ID (if submitted by parent)
  "ten_phu_huynh": string | null,        // Parent name (if submitted by parent)

  "ly_do": string,
  "thoi_gian_xin_ve": timestamp,
  "ngay_xin_ve": timestamp,
  "thoi_gian_xuong_truong": timestamp | null,
  "ngay_xuong_truong": timestamp | null,

  "ten_nguoi_don": string,
  "cccd_nguoi_don": string,        // 12 digits
  "sdt_nguoi_don": string,          // Vietnamese phone format

  "danh_sach_ngay_cat_com": array,       // Array of timestamps (dates only) for meal deduction

  "id_nguoi_duyet": string | null,       // Approver ID (teacher who approved)
  "ten_nguoi_duyet": string | null,      // Approver name
  "thoi_gian_duyet": timestamp | null,   // Approval timestamp

  "trang_thai": string,              // Enum value
  "nguon": string,                   // Enum value
  "ly_do_tu_choi": string | null,
  "created_at": timestamp,
  "updated_at": timestamp | null
}
```

**Indexes Required:**
```
- trang_thai (ascending)
- id_lop (ascending)
- created_at (descending)
- Composite: trang_thai + id_lop
- Composite: id_hoc_sinh + created_at (descending)
```

### Service Layer - XinVePhepService

**New File**: `lib/services/xin_ve_phep_service.dart`

```dart
class XinVePhepService {
  static const String collection = 'xin_ve_phep';

  // CRUD Operations
  static Future<String> create(XinVePhep xin);
  static Future<void> update(String id, XinVePhep xin);
  static Future<void> delete(String id);
  static Future<XinVePhep?> getById(String id);

  // Query Methods
  static Future<List<XinVePhep>> getByHocSinh(String idHocSinh);
  static Future<List<XinVePhep>> getByLop(String idLop);
  static Future<List<XinVePhep>> getByTrangThai(TrangThaiVePhep trangThai);

  // Approval-specific queries
  static Future<List<XinVePhep>> getPendingApprovals();
  static Future<List<XinVePhep>> getPendingForTeacher(String idLop);

  // Streams
  static Stream<List<XinVePhep>> streamByHocSinh(String idHocSinh);
  static Stream<List<XinVePhep>> streamPendingApprovals();
  static Stream<List<XinVePhep>> streamPendingForTeacher(String idLop);

  // Approval actions
  static Future<void> approve(String id, String teacherId, String teacherName);
  static Future<void> reject(String id, String reason, String teacherId);
  static Future<void> markReturned(String id, DateTime returnTime);
}
```

### UI Components - New Screens

#### For Students/Parents

**New File**: `lib/screens/hoc_sinh/xin_ve_phep/dang_ky_ve_phep_screen.dart`
- Form to request leave permission
- Sections:
  1. Student info (auto-filled)
  2. Leave dates & times
  3. Guardian pickup information
  4. Meal deduction (auto-calculated, editable)
  5. Reason for leave

**New File**: `lib/screens/hoc_sinh/xin_ve_phep/lich_su_ve_phep_screen.dart`
- List of student's leave permission history
- Show status, dates, approval chain
- Filter by status

**New File**: `lib/screens/phu_huynh/xin_ve_phep/dang_ky_ve_phep_phu_huynh_screen.dart`
- Similar to student screen but for parents
- Can select which child (if multiple)

#### For Teachers

**New File**: `lib/screens/giao_vien/duyet_ve_phep/duyet_ve_phep_screen.dart`
- List of leave requests waiting for teacher approval
- Shows: student info, leave dates, guardian info, meal deduction
- Actions: Approve, Reject
- Filter by date, class
- Available to both duty teachers and homeroom teachers

**New File**: `lib/widgets/xin_ve_phep_detail_dialog.dart`
- Dialog to display full leave permission details
- Shows approval history, guardian info, all timestamps

### Validation Rules

**1. Guardian Information**
```dart
// CCCD Validation
bool isValidCCCD(String cccd) {
  return RegExp(r'^\d{12}$').hasMatch(cccd);
}

// Phone Validation (Vietnamese format)
bool isValidPhone(String phone) {
  return RegExp(r'^(0|\+84)(3|5|7|8|9)\d{8}$').hasMatch(phone);
}

// All required
- tenNguoiDon: not empty, min 3 chars
- cccdNguoiDon: exactly 12 digits
- sdtNguoiDon: valid Vietnamese phone
```

**2. Leave Date Validation**
```dart
// Leave start date must be >= today
// If return date specified, must be > leave date
// Generate list of dates between leave date and return date for meal deduction selection
```

**3. Meal Deduction Date Selection**
```dart
// Generate list of available dates
List<DateTime> generateAvailableDates(DateTime leave, DateTime? return) {
  if (return == null) return [];
  List<DateTime> dates = [];
  DateTime current = DateTime(leave.year, leave.month, leave.day);
  DateTime end = DateTime(return.year, return.month, return.day);

  while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
    dates.add(current);
    current = current.add(Duration(days: 1));
  }
  return dates;
}

// Constraints
- danhSachNgayCatCom must be a list of dates (no time component)
- All dates in list must be between ngayXinVe and ngayXuongTruong (inclusive)
- List can be empty (student doesn't deduct any meals)
- User can select/deselect individual dates via checkbox or calendar UI
- Default: All dates selected (full meal deduction)
```

**4. Approval Permissions**
```dart
// Teacher approval
- User must have role giaoVien
- User must be EITHER:
  * Assigned as duty teacher (check phan_cong_truc_ban), OR
  * Homeroom teacher of the student's class (check phan_cong_chu_nhiem)
```

### UI/UX Flow

#### Student Request Flow
1. Student opens main menu → "Xin Về Phép"
2. Fills form: dates, guardian info, reason
3. System generates list of dates between leave date and return date
4. Student selects which dates to deduct meals (default: all dates selected)
   - UI shows checkboxes or calendar with selectable dates
   - Can deselect dates if student will eat at school on specific days
5. Submit → Creates record with `choDuyet` and selected meal deduction dates
6. Student sees request in history with "Chờ duyệt" status

#### Teacher Approval Flow
1. Teacher opens "Duyệt Về Phép"
2. Sees list of requests with `choDuyet` status
   - Duty teachers see all pending requests
   - Homeroom teachers see pending requests for their class only
3. Clicks request → Views full details (guardian info, dates, meal deduction, etc.)
4. Approves → Status changes to `daDuyet`, records teacher ID, name & timestamp
5. OR Rejects → Status changes to `tuChoi`, records rejection reason

### Error Handling

**Form Validation Errors**
- Display field-level errors in Vietnamese
- Disable submit until all validations pass
- Show helpful messages for format errors

**Permission Errors**
- Check roles before showing approval screens
- Verify teacher assignments before allowing approval
- Show friendly error if user lacks permission

**Network/Firebase Errors**
- Show loading states during async operations
- Retry failed operations with user confirmation
- Timeout handling for long operations

### Performance Considerations

**Query Optimization**
- Use Firestore indexes for common queries
- Limit query results with pagination if needed
- Use streams only for active screens (unsubscribe on dispose)

**Data Denormalization**
- Store teacher names to avoid joins
- Store class name for easier display
- Trade-off: Slightly more storage for faster queries

### Migration Strategy

**No Migration Needed**
- This is a completely new system
- Existing `xin_ra_vao` data and screens unchanged
- Both systems coexist independently
- No data migration or conversion required

### Integration Points

**Navigation Updates**
- Add "Xin Về Phép" menu item in student main screen
- Add "Xin Về Phép" menu item in parent main screen
- Add "Duyệt Về Phép" menu item in teacher menu (available to all teachers)

**User Roles**
- Use existing `UserRole` enum (no changes needed)
- Use existing role-based routing

## Trade-offs

### Decision: Separate collection vs extending existing
**Chosen:** Separate `xin_ve_phep` collection
**Rationale:**
- Clear separation of concerns
- No risk of breaking existing functionality
- Different approval workflows
- Different data requirements
**Trade-off:** More code to maintain, but safer and clearer

### Decision: Denormalize teacher/class names
**Chosen:** Store names in addition to IDs
**Rationale:** Faster display, fewer lookups
**Trade-off:** Data consistency risk if names change (acceptable for historical records)

### Decision: Store both date and timestamp for leave dates
**Chosen:** Store both `ngayXinVe` (date only) and `thoiGianXinVe` (full timestamp)
**Rationale:** Easier date-range queries and better UX for time display
**Trade-off:** Slightly redundant data, but worth it for performance and clarity

### Decision: Single approval screen for all teachers
**Chosen:** One approval screen accessible to both duty and homeroom teachers
**Rationale:** Simplified workflow, either teacher type can approve
**Trade-off:** Need role-based filtering (duty teachers see all, homeroom see their class only)
