# Design: Student Attendance Tracking

## Context

The school operates on a boarding model where students attend 3 periods daily: morning (sáng), noon (trưa), and afternoon/evening (chiều tối). Each class may have different time periods depending on their schedule. The system needs to:
1. Allow admins to configure attendance periods per class per weekday
2. Enable students to check in via existing card/face authentication
3. Track late arrivals while respecting approved leave permissions
4. Provide visibility to teachers, parents, and administrators

## Goals / Non-Goals

**Goals:**
- Configurable attendance periods per class per weekday
- Reuse existing camera and card authentication logic
- Integrate with existing leave permission system
- Provide clear late history and statistics

**Non-Goals:**
- Automatic notification for late arrivals (future enhancement)
- GPS-based location verification
- QR code check-in

## Data Model

### Embedded in `lop` collection: `cau_hinh_diem_danh` field
Attendance config is embedded as a map in the `Lop` model for simplicity.

```
// In lop document:
{
  ...existing fields...,
  cau_hinh_diem_danh: {
    "1": {  // Monday (1=Monday, 7=Sunday)
      "ca_sang": {"bat_dau": "07:00", "ket_thuc": "07:30"},
      "ca_trua": {"bat_dau": "13:00", "ket_thuc": "13:30"},
      "ca_chieu_toi": {"bat_dau": "19:00", "ket_thuc": "19:30"}
    },
    "2": { ... },  // Tuesday
    "3": { ... },  // Wednesday
    "4": { ... },  // Thursday
    "5": { ... },  // Friday
    "6": { ... },  // Saturday
    "7": { ... }   // Sunday
  }
}
```

**Benefits of embedding:**
- Single read to get class + config
- Fewer Firestore collections
- Atomic updates
- Simpler queries

### Collection: `diem_danh` (Attendance Records)
Stores individual check-in records.

```
{
  id: string,
  id_hoc_sinh: string,
  id_lop: string,
  ngay: Timestamp,          // Date only (time at 00:00)
  ca: string,               // "sang" | "trua" | "chieu_toi"
  thoi_gian_checkin: Timestamp,
  phuong_thuc: string,      // "the" | "khuon_mat"
  trang_thai: string,       // "dung_gio" | "tre" | "vang_phep"
  ghi_chu: string?,
  created_at: Timestamp
}
```

## Decisions

### Decision 1: Embed attendance config in class model
- **What**: Store attendance config as a map field in `lop` collection instead of separate collection
- **Why**: Data size is small (7 days × 3 periods × 2 times = 42 strings), embedding simplifies reads and updates
- **Alternative**: Separate collection - rejected for unnecessary complexity

### Decision 2: Reuse existing authentication screens
- **What**: Extract core camera/card logic into reusable widgets from `XacThucKhuonMatScreen` and `XacThucTheScreen`
- **Why**: DRY principle, existing code is working and tested
- **Alternative**: Copy-paste code - rejected for maintainability

### Decision 3: Pre-calculate late status on check-in
- **What**: Calculate `trang_thai` (on-time/late/excused) at check-in time, not at query time
- **Why**: Simplifies queries, avoids recalculating config for each record
- **Alternative**: Calculate on query - rejected for performance with large datasets

### Decision 4: Use leave permission dates to auto-mark excused
- **What**: Check `xin_ve_phep.danh_sach_ngay_cat_com` or date range before marking late
- **Why**: Consistent with meal deduction logic, single source of truth for absences
- **Alternative**: Manual excused marking - rejected for admin overhead

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Web Admin                                │
├─────────────────────────────────────────────────────────────────┤
│  CauHinhDiemDanhScreen     │  ThongKeDiMuonScreen               │
│  - Per-class config        │  - Statistics by class/day        │
│  - Weekday time periods    │  - Late student counts            │
└────────────────────────────┴────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        Mobile App                               │
├─────────────────────────────────────────────────────────────────┤
│  DiemDanhScreen (Student)                                       │
│  ├─ DiemDanhTheWidget      │  Uses CardCameraWidget             │
│  └─ DiemDanhKhuonMatWidget │  Uses FaceCameraWidget             │
├─────────────────────────────────────────────────────────────────┤
│  LichSuDiMuonScreen (Teacher/Parent)                            │
│  - Filter by student/class │  - Date range selection            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        Shared Widgets                           │
├─────────────────────────────────────────────────────────────────┤
│  CardCameraWidget          │  FaceCameraWidget                  │
│  - Extracted from          │  - Extracted from                  │
│    XacThucTheScreen        │    XacThucKhuonMatScreen           │
└────────────────────────────┴────────────────────────────────────┘
```

## Service Layer

### CauHinhDiemDanhService
- `getConfigByLop(idLop)` - Get all weekday configs for a class
- `getConfigByLopAndDay(idLop, dayOfWeek)` - Get specific day config
- `updateConfig(config)` - Create/update config
- `deleteConfig(id)` - Delete config

### DiemDanhService
- `checkIn(idHocSinh, ca, phuongThuc)` - Record check-in, calculate late status
- `getByStudent(idHocSinh, startDate, endDate)` - Student's attendance history
- `getByClass(idLop, date)` - Class attendance for a day
- `getLateStatistics(idLop, startDate, endDate)` - Late counts by class
- `isOnLeave(idHocSinh, date)` - Check if student has approved leave

## Risks / Trade-offs

### Risk 1: Time zone handling
- **Risk**: Server time vs device time discrepancy
- **Mitigation**: Use device local time for check-in, store as UTC in Firestore

### Risk 2: Config changes mid-day
- **Risk**: Admin changes attendance time after some students checked in
- **Mitigation**: Use check-in time snapshot, don't recalculate historical records

### Risk 3: Multiple check-ins per period
- **Risk**: Student checks in multiple times
- **Mitigation**: Only record first check-in per student per period per day

## Open Questions

- Should we support bulk attendance import (e.g., teacher marks entire class)?
- Should late notifications be sent to parents via push notification?
