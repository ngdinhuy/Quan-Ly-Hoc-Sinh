import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/xin_ve_phep.dart';
import 'firebase_service.dart';

class XinVePhepService {
  static const String collection = 'xin_ve_phep';

  // CRUD Operations

  static Future<String> createXinVePhep(XinVePhep xinVePhep) async {
    final docRef = await FirebaseService.firestore
        .collection(collection)
        .add(xinVePhep.toFirestore());
    return docRef.id;
  }

  static Future<void> updateXinVePhep(String id, XinVePhep xinVePhep) async {
    await FirebaseService.firestore
        .collection(collection)
        .doc(id)
        .update(xinVePhep.toFirestore());
  }

  static Future<void> deleteXinVePhep(String id) async {
    await FirebaseService.firestore.collection(collection).doc(id).delete();
  }

  static Future<XinVePhep?> getXinVePhepById(String id) async {
    final doc = await FirebaseService.firestore
        .collection(collection)
        .doc(id)
        .get();

    if (doc.exists) {
      return XinVePhep.fromFirestore(doc);
    }
    return null;
  }

  // Query Methods

  static Future<List<XinVePhep>> getXinVePhepByHocSinh(String idHocSinh) async {
    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('id_hoc_sinh', isEqualTo: idHocSinh)
        .orderBy('created_at', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => XinVePhep.fromFirestore(doc))
        .toList();
  }

  static Future<List<XinVePhep>> getXinVePhepByLop(String idLop) async {
    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('id_lop', isEqualTo: idLop)
        .orderBy('created_at', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => XinVePhep.fromFirestore(doc))
        .toList();
  }

  static Future<List<XinVePhep>> getXinVePhepByTrangThai(
    TrangThaiVePhep trangThai,
  ) async {
    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('trang_thai', isEqualTo: _getTrangThaiString(trangThai))
        .orderBy('created_at', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => XinVePhep.fromFirestore(doc))
        .toList();
  }

  // Approval-specific queries

  /// Get all pending leave permissions (for duty teachers who can see all classes)
  static Future<List<XinVePhep>> getPendingApprovals() async {
    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('trang_thai', isEqualTo: 'cho_duyet')
        .orderBy('created_at', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => XinVePhep.fromFirestore(doc))
        .toList();
  }

  /// Get pending leave permissions for a specific class (for homeroom teachers)
  static Future<List<XinVePhep>> getPendingForTeacher(String idLop) async {
    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('trang_thai', isEqualTo: 'cho_duyet')
        .where('id_lop', isEqualTo: idLop)
        .orderBy('created_at', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => XinVePhep.fromFirestore(doc))
        .toList();
  }

  // Streams

  static Stream<List<XinVePhep>> streamXinVePhepByHocSinh(String idHocSinh) {
    return FirebaseService.firestore
        .collection(collection)
        .where('id_hoc_sinh', isEqualTo: idHocSinh)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => XinVePhep.fromFirestore(doc)).toList(),
        );
  }

  static Stream<List<XinVePhep>> streamPendingApprovals() {
    return FirebaseService.firestore
        .collection(collection)
        .where('trang_thai', isEqualTo: 'cho_duyet')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => XinVePhep.fromFirestore(doc)).toList(),
        );
  }

  static Stream<List<XinVePhep>> streamPendingForTeacher(String idLop) {
    return FirebaseService.firestore
        .collection(collection)
        .where('trang_thai', isEqualTo: 'cho_duyet')
        .where('id_lop', isEqualTo: idLop)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => XinVePhep.fromFirestore(doc)).toList(),
        );
  }

  // Approval actions

  /// Approve a leave permission request
  static Future<void> approve(
    String id,
    String teacherId,
    String teacherName,
  ) async {
    await FirebaseService.firestore.collection(collection).doc(id).update({
      'trang_thai': 'da_duyet',
      'id_nguoi_duyet': teacherId,
      'ten_nguoi_duyet': teacherName,
      'thoi_gian_duyet': Timestamp.now(),
      'updated_at': Timestamp.now(),
    });
  }

  /// Reject a leave permission request
  static Future<void> reject(String id, String reason, String teacherId) async {
    await FirebaseService.firestore.collection(collection).doc(id).update({
      'trang_thai': 'tu_choi',
      'ly_do_tu_choi': reason,
      'id_nguoi_duyet': teacherId,
      'updated_at': Timestamp.now(),
    });
  }

  /// Mark student as returned to school
  static Future<void> markReturned(String id, DateTime returnTime) async {
    await FirebaseService.firestore.collection(collection).doc(id).update({
      'trang_thai': 'da_ve_truong',
      'thoi_gian_xuong_truong': Timestamp.fromDate(returnTime),
      'updated_at': Timestamp.now(),
    });
  }

  // Statistics queries

  /// Get all approved leave permissions that have meal deduction on a specific date
  /// Used for meal statistics calculation
  static Future<List<XinVePhep>> getApprovedByMealDate(DateTime date) async {
    // Get all approved leave permissions
    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('trang_thai', isEqualTo: 'da_duyet')
        .get();

    // Filter in Dart: check if danh_sach_ngay_cat_com contains the date
    // Firestore doesn't support array-contains with Timestamp comparison well
    final dateOnly = DateTime(date.year, date.month, date.day);

    return querySnapshot.docs
        .map((doc) => XinVePhep.fromFirestore(doc))
        .where(
          (xinVePhep) => xinVePhep.danhSachNgayCatCom.any((mealDate) {
            final mealDateOnly = DateTime(
              mealDate.year,
              mealDate.month,
              mealDate.day,
            );
            return mealDateOnly.isAtSameMomentAs(dateOnly);
          }),
        )
        .toList();
  }

  /// Get approved leave permissions for a specific student within date range
  static Future<List<XinVePhep>> getApprovedByStudentDateRange(
    String idHocSinh,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('id_hoc_sinh', isEqualTo: idHocSinh)
        .where('trang_thai', isEqualTo: 'da_duyet')
        .get();

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    // Filter: any meal deduction date falls within the range
    return querySnapshot.docs
        .map((doc) => XinVePhep.fromFirestore(doc))
        .where(
          (xinVePhep) => xinVePhep.danhSachNgayCatCom.any((mealDate) {
            final mealDateOnly = DateTime(
              mealDate.year,
              mealDate.month,
              mealDate.day,
            );
            return !mealDateOnly.isBefore(start) && !mealDateOnly.isAfter(end);
          }),
        )
        .toList();
  }

  /// Get all approved leave permissions for a date range (for monthly statistics)
  static Future<List<XinVePhep>> getApprovedInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot = await FirebaseService.firestore
        .collection(collection)
        .where('trang_thai', isEqualTo: 'da_duyet')
        .get();

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    // Filter: any meal deduction date falls within the range
    return querySnapshot.docs
        .map((doc) => XinVePhep.fromFirestore(doc))
        .where(
          (xinVePhep) => xinVePhep.danhSachNgayCatCom.any((mealDate) {
            final mealDateOnly = DateTime(
              mealDate.year,
              mealDate.month,
              mealDate.day,
            );
            return !mealDateOnly.isBefore(start) && !mealDateOnly.isAfter(end);
          }),
        )
        .toList();
  }

  // Helper methods

  static String _getTrangThaiString(TrangThaiVePhep trangThai) {
    switch (trangThai) {
      case TrangThaiVePhep.choDuyet:
        return 'cho_duyet';
      case TrangThaiVePhep.daDuyet:
        return 'da_duyet';
      case TrangThaiVePhep.daVeTruong:
        return 'da_ve_truong';
      case TrangThaiVePhep.tuChoi:
        return 'tu_choi';
    }
  }
}
