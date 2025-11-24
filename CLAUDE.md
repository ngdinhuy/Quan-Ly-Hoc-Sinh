<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based student management system (Quản Lý Học Sinh) that tracks student entry/exit, manages school data, and provides role-based interfaces for teachers, students, and parents. The application supports both web and mobile platforms with Firebase as the backend.

## Common Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on mobile (requires emulator/device)
flutter run

# Run with specific device
flutter devices  # List available devices
flutter run -d <device-id>

# Hot reload is available during development (press 'r' in terminal)
# Hot restart (press 'R' in terminal)
```

### Code Quality
```bash
# Run linter
flutter analyze

# Format code
dart format lib/

# Format specific file
dart format lib/path/to/file.dart
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

### Building
```bash
# Build APK for Android
flutter build apk

# Build app bundle for Android
flutter build appbundle

# Build for iOS (requires macOS)
flutter build ios

# Build for web
flutter build web
```

## Architecture Overview

### Multi-Role System
The application has 4 distinct user roles with separate UI flows:
- **Admin** (`UserRole.admin`): Full system management via web interface
- **Giáo Viên** (Teacher - `UserRole.giaovien`): Class management, entry/exit approval, duty roster
- **Học Sinh** (Student - `UserRole.hocsinh`): Self check-in/out, view history, request exit permissions
- **Phụ Huynh** (Parent - `UserRole.phuhuynh`): View child's attendance, request visits, check-in history

**Platform-specific entry points:**
- Web: Goes directly to `AuthScreen` (admin-focused)
- Mobile: Shows `ChonLoaiVaiTroScreen` for role selection, then specific login screens

### Directory Structure

```
lib/
├── config/              # Google Sign-In and Firebase configurations
├── models/              # Data models matching Firestore collections
│   ├── user.dart        # UserModel with UserRole enum
│   ├── hoc_sinh.dart    # Student model
│   ├── giao_vien.dart   # Teacher model
│   ├── phu_huynh.dart   # Parent model
│   ├── lop.dart         # Class model
│   ├── xin_ra_vao.dart  # Entry/exit request model
│   └── ...
├── services/            # Firebase and business logic layer
│   ├── firebase_service.dart      # Firestore and Storage instances
│   ├── local_data_service.dart    # SharedPreferences singleton
│   ├── hoc_sinh_service.dart      # Student CRUD operations
│   ├── giao_vien_service.dart     # Teacher operations
│   └── ...
├── screens/             # UI organized by user role
│   ├── giao_vien/       # Teacher screens
│   ├── hoc_sinh/        # Student screens (includes face/card auth)
│   ├── phu_huynh/       # Parent screens
│   └── component_widget/ # Shared components
├── widgets/             # Reusable form dialogs and components
└── utils/               # Utility classes (e.g., StringExt.dart)
```

### State Management
The project uses **both Provider and Riverpod** (see pubspec.yaml). When adding state management, check existing patterns in the specific role's screens to maintain consistency.

### Firebase Architecture

**Collections structure:**
- `users` - UserModel with role-based access
- `hoc_sinh` - Student records with card/face authentication URLs
- `giao_vien` - Teacher records
- `phu_huynh` - Parent records
- `lop` - Class records
- `khoi` - Grade level records
- `truong` - School records
- `xin_ra_vao` - Entry/exit requests with approval workflow (temporary exits)
- `xin_ve_phep` - Leave permission requests (multi-day absences)
- `phan_cong_truc_ban` - Duty assignments
- `phan_cong_chu_nhiem` - Homeroom assignments
- `tham_ph` - Parent visit records

**Service pattern:**
All Firebase operations go through service classes in `lib/services/`. Each service:
- Has a static `collection` constant for the Firestore collection name
- Provides CRUD operations (create, update, delete, get by ID)
- Provides query methods (e.g., `getHocSinhByLop`, `streamHocSinhByLop`)
- Uses `FirebaseService.firestore` and `FirebaseService.storage` for access
- Returns models from `lib/models/` using `fromFirestore()` factory methods

**Example pattern:**
```dart
static Future<ModelName?> getById(String id) async {
  final doc = await FirebaseService.firestore
      .collection(collection)
      .doc(id)
      .get();
  if (doc.exists) {
    return ModelName.fromFirestore(doc);
  }
  return null;
}
```

### Local Storage

`LocalDataService` is a singleton that manages user session data using SharedPreferences:
- Initialize in `main()`: `LocalDataService.instance.init()`
- Stores user ID, role, and role-specific IDs (student, teacher)
- Used for maintaining login state across app restarts
- Access via `LocalDataService.instance`

### Entry/Exit Tracking System

Key feature: Students can check in/out using:
1. **Card authentication** (`xac_thuc_the_screen.dart`) - Scan student ID card
2. **Face authentication** (`xac_thuc_khuon_mat_screen.dart`) - Uses camera for face recognition

Entry/exit requests flow through `XinRaVao` model with states:
- `choDuyet` - Pending approval
- `daDuyet` - Approved
- `daVao` - Student returned
- `tuChoi` - Rejected

Teachers with duty assignments can approve/reject requests via `truc_ban_screen.dart`.

### Leave Permission System (Xin Về Phép)

**IMPORTANT**: This is a SEPARATE system from the temporary entry/exit (`XinRaVao`) system. The leave permission system handles multi-day absences where students leave school for extended periods (vacations, family matters, etc.).

Key feature: Leave permissions can be requested through three different entry flows:

**Request submission sources (`NguonVePhep` enum):**
1. **Student submission** (`appHocSinh`):
   - Students submit via `dang_ky_ve_phep_screen.dart` (app học sinh)
   - Student info auto-filled from their profile

2. **Parent submission** (`appPhuHuynh`):
   - Parents submit via `dang_ky_ve_phep_phu_huynh_screen.dart` (app phụ huynh)
   - Child info auto-filled from parent's linked student (`PhuHuynh.idHs`)
   - Guardian info auto-filled from parent's profile (name, CCCD, phone)
   - Parents can view history via `lich_su_ve_phep_phu_huynh_screen.dart`

3. **Teacher/admin manual entry** (`giaoVienNhap`):
   - Teachers can create requests on behalf of students (e.g., phone/paper submissions)
   - Entry form accessible via `giao_vien_nhap_ve_phep_form_dialog.dart`
   - Includes student search by card number or name
   - Optional pre-approval checkbox to bypass approval workflow

**All requests include:** leave date/time, return date/time, guardian info (name, CCCD, phone), reason, meal deduction dates

**Approval flow (single-level):**
- Requests flow through `XinVePhep` model with states:
  - `choDuyet` - Pending approval
  - `daDuyet` - Approved by teacher
  - `tuChoi` - Rejected with reason
  - `daVeTruong` - Student returned to school

**Teacher approval:**
- Teachers approve/reject via `duyet_ve_phep_screen.dart`
- Role-based filtering:
  - **Duty teachers** (`PhanCongTrucBan`) see ALL pending requests
  - **Homeroom teachers** (`PhanCongChuNhiem`) see only THEIR CLASS requests
- Teachers can view full details via `xin_ve_phep_detail_dialog.dart`
- Rejection requires a reason

**Admin management (web):**
- Admins manage all leave permissions via `ve_phep_admin_screen.dart`
- Follows `ra_vao_screen.dart` pattern with 3 status tabs:
  - **Chờ Duyệt** (Pending) - approve/reject actions
  - **Đã Duyệt** (Approved) - view approved requests
  - **Từ Chối** (Rejected) - view rejected requests
- Class dropdown filter to view permissions by class
- Full CRUD operations:
  - **Create**: "Thêm Yêu Cầu" button opens teacher entry dialog
  - **Approve/Reject**: Green check / red X buttons on pending tab
  - **Edit**: Blue pencil icon on all tabs (uses enhanced dialog with edit mode)
  - **Delete**: Red trash icon on all tabs
- DataTable displays: student info, dates, guardian, reason, source, actions
- Shows all sources (student, parent, teacher-entered) with source badges

**Data validation:**
- CCCD: Must be exactly 12 digits (see `validation_utils.dart`)
- Phone: Vietnamese format (0xxxxxxxxx or +84xxxxxxxxx)
- Meal deduction dates: Auto-generated from leave/return date range
- All dates validated to ensure logical ordering

**Related files:**
- Model: `lib/models/xin_ve_phep.dart`
- Service: `lib/services/xin_ve_phep_service.dart`
- Utilities: `lib/utils/validation_utils.dart`
- Student screens: `lib/screens/hoc_sinh/xin_ve_phep/`
- Parent screens: `lib/screens/phu_huynh/xin_ve_phep/` (request & history)
- Teacher approval screen: `lib/screens/giao_vien/duyet_ve_phep/`
- Admin management screen: `lib/screens/ve_phep_admin_screen.dart` (web only)
- Teacher entry dialog: `lib/widgets/giao_vien_nhap_ve_phep_form_dialog.dart` (supports create & edit modes)
- Detail dialog: `lib/widgets/xin_ve_phep_detail_dialog.dart`

### Meal Statistics (Thống Kê Xuất Ăn)

Admin feature for tracking daily meal counts by class, based on approved leave permission meal deductions.

**Key features:**
- View meal statistics by date (daily view)
- View monthly overview with daily totals
- Filter by specific class
- Export to Excel (.xlsx format)

**Calculations:**
- **Tổng HS (Total students)**: Count from `hoc_sinh` collection per class
- **Cắt cơm (Meal deductions)**: Count distinct students from approved `xin_ve_phep` where `danh_sach_ngay_cat_com` contains selected date
- **Ăn cơm (Students eating)**: Total students - Meal deductions

**Data source:**
- Only counts from **approved** leave permissions (`trangThai == daDuyet`)
- Uses `danh_sach_ngay_cat_com` array field for date matching
- Each student counted once even with multiple approved leaves on same date

**Related files:**
- Screen: `lib/screens/thong_ke_xuat_an_screen.dart` (web admin only)
- Service: `lib/services/thong_ke_xuat_an_service.dart`
- Query methods in: `lib/services/xin_ve_phep_service.dart`

**Dependencies:**
- `excel` package for Excel export
- `web` package for browser download

### Student Attendance Tracking (Điểm Danh)

System for tracking student attendance check-ins with configurable time periods per class and per weekday.

**Key features:**
- **Configurable time periods**: Admins can configure attendance periods (morning/noon/afternoon-evening) per class per weekday via web interface
- **Student check-in**: Students check in via face scan on mobile app
- **Late calculation**: Automatic late status based on check-in time vs. configured period end time
- **Absence tracking**: Students who don't check in and have no approved leave are counted as absent (calculated on-demand, not stored)
- **Leave integration**: Students with approved leave permissions are excluded from absence counts
- **Late/Absence history**: Teachers can view late history for their homeroom class; Parents can view their child's late and absence history
- **Admin statistics**: View combined attendance statistics (late + absent) by class and date on web admin

**Attendance periods (3 per day):**
- `sang` (Morning): Default 07:00-07:30
- `trua` (Noon): Default 13:00-13:30
- `chieuToi` (Afternoon/Evening): Default 19:00-19:30

**Attendance status (`TrangThaiDiemDanh`):**
- `dungGio`: On time (check-in ≤ period end time)
- `tre`: Late (check-in > period end time)
- `vangPhep`: Excused absence (student has approved leave)

**Check-in methods (`PhuongThucDiemDanh`):**
- `the`: Card scan
- `khuonMat`: Face scan

**Data model:**
- Attendance config is embedded in `Lop` model as `cauHinhDiemDanh` (Map<String, CaHocConfig>)
- Key = day of week ("1"-"7" for Monday-Sunday)
- Each `CaHocConfig` contains 3 `ThoiGianCa` (start/end times for each period)

**Absence calculation logic:**
- Absence = All students in class - Checked-in students - Students on approved leave
- Absences only calculated for ended periods (current time > period end + 30 min buffer)
- Calculated on-demand, not stored in database

**Related files:**
- Model: `lib/models/diem_danh.dart`
- Service: `lib/services/diem_danh_service.dart`
- Admin config screen: `lib/screens/cau_hinh_diem_danh_screen.dart` (web only)
- Admin statistics: `lib/screens/thong_ke_di_muon_screen.dart` (web only, shows late + absent)
- Student check-in: `lib/screens/hoc_sinh/diem_danh/diem_danh_screen.dart`
- Teacher late history: `lib/screens/giao_vien/lich_su_di_muon/lich_su_di_muon_screen.dart`
- Parent late history: `lib/screens/phu_huynh/lich_su_di_muon/lich_su_di_muon_phu_huynh_screen.dart`
- Parent absence history: `lib/screens/phu_huynh/lich_su_vang_mat/lich_su_vang_mat_screen.dart`
- Camera widgets: `lib/widgets/face_camera_widget.dart`, `lib/widgets/card_camera_widget.dart`

**Firebase collection:** `diem_danh`

## Key Development Patterns

### Adding a New Screen
1. Create screen file in appropriate role folder under `lib/screens/[role]/`
2. Follow naming convention: `feature_name_screen.dart` with `FeatureNameScreen` class
3. Add navigation in the role's main screen or login flow
4. For dialogs/forms, create in `lib/widgets/` with `_form_dialog.dart` suffix

### Adding a New Model
1. Create model file in `lib/models/`
2. Include Firestore serialization: `toFirestore()` and `fromFirestore()` methods
3. Use `Timestamp` for DateTime fields in Firestore
4. Create corresponding service in `lib/services/` with CRUD operations
5. Follow snake_case for Firestore field names (e.g., `ho_ten`, `id_lop`)

### Working with Firebase
- Always use service layer, never call Firestore directly from UI
- Handle null cases when fetching data
- Use streams (`snapshots()`) for real-time updates in UI
- Store file URLs in Firestore; upload files to Firebase Storage via `image_service.dart`

### Responsive Design
- Uses `responsive_framework` package (see pubspec.yaml)
- Check existing screens for responsive patterns
- App should work on both mobile and web

### Authentication
- Firebase Auth with Google Sign-In for web/admin
- Custom authentication (card number + password) for mobile roles
- Check role after authentication and route to appropriate main screen

## Important Notes

- **Language**: All UI text and data fields use Vietnamese
- **Snake case**: Firestore fields use snake_case (e.g., `so_the_hoc_sinh`, `id_lop`)
- **Camel case**: Dart code uses camelCase
- **Platform detection**: Use `kIsWeb` from `package:flutter/foundation.dart` to differentiate web/mobile
- **Camera permissions**: Required for face authentication (handled by `permission_handler` package)
- **Image handling**: Uses both `image_picker` and `camera` packages depending on use case

## Firebase Configuration

Firebase is initialized in [main.dart:14-24](lib/main.dart#L14-L24) using `firebase_options.dart`. Platform-specific configurations are in:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `web/index.html` (Firebase JS SDK config)
