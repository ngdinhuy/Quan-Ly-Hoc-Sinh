import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quan_ly_hoc_sinh/models/giao_vien.dart';
import 'package:quan_ly_hoc_sinh/models/phan_cong_chu_nhiem.dart';

class PhanCongChuNhiemService {
  final CollectionReference phanCongCollection = FirebaseFirestore.instance
      .collection('phan_cong_chu_nhiem');

  // Create a new assignment
  static Future<PhanCongChuNhiem> create(PhanCongChuNhiem phanCong) async {
    try {
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('phan_cong_chu_nhiem')
          .add(phanCong.toFirestore());

      // Return the created assignment with the new ID
      return phanCong.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create assignment: $e');
    }
  }

  // Update an existing assignment
  static Future<void> update(PhanCongChuNhiem phanCong) async {
    try {
      if (phanCong.id == null) {
        throw Exception('Cannot update assignment without an ID');
      }

      await FirebaseFirestore.instance
          .collection('phan_cong_chu_nhiem')
          .doc(phanCong.id)
          .update(phanCong.toFirestore());
    } catch (e) {
      throw Exception('Failed to update assignment: $e');
    }
  }

  // Get assignment by ID
  static Future<PhanCongChuNhiem?> getById(String id) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('phan_cong_chu_nhiem')
          .doc(id)
          .get();

      if (doc.exists) {
        return PhanCongChuNhiem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch assignment: $e');
    }
  }

  // Get all assignments
  static Future<List<PhanCongChuNhiem>> getAll() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('phan_cong_chu_nhiem')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PhanCongChuNhiem.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch assignments: $e');
    }
  }

  // Delete an assignment
  static Future<void> delete(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('phan_cong_chu_nhiem')
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete assignment: $e');
    }
  }

  /// Get homeroom teacher info by class ID
  /// Returns a map with teacher info: {idGiaoVien, tenGiaoVien} or null if not found
  static Future<GiaoVien?> getTeacherByClassId(String idLop) async {
    try {
      // Get active homeroom assignment for this class
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('phan_cong_chu_nhiem')
          .where('id_lop', isEqualTo: idLop)
          .orderBy('created_at', descending: true)
          .get();

      if (snapshot.docs.isEmpty) return null;

      // Find active assignment (no end date or end date is in the future)
      for (var doc in snapshot.docs) {
        final assignment = PhanCongChuNhiem.fromFirestore(doc);
        if (assignment.denNgay == null ||
            assignment.denNgay!.isAfter(DateTime.now())) {
          // Get teacher info
          DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
              .collection('giao_vien')
              .doc(assignment.idGv)
              .get();

          if (teacherDoc.exists) {
            final teacherData = teacherDoc.data() as Map<String, dynamic>;
            return GiaoVien.fromFirestore(teacherDoc);
          }
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get teacher by class: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getClassesByTeacherId(
    String idGiaoVien,
  ) async {
    try {
      // Get all homeroom assignments for this teacher
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('phan_cong_chu_nhiem')
          .where('id_gv', isEqualTo: idGiaoVien)
          .orderBy('created_at', descending: true)
          .get();

      List<PhanCongChuNhiem> assignments = snapshot.docs
          .map((doc) => PhanCongChuNhiem.fromFirestore(doc))
          .toList();

      // Filter active assignments (no end date or end date is in the future)
      assignments = assignments
          .where(
            (assignment) =>
                assignment.denNgay == null ||
                assignment.denNgay!.isAfter(DateTime.now()),
          )
          .toList();

      // For each assignment, get the class information
      List<Map<String, dynamic>> classesWithInfo = [];

      for (var assignment in assignments) {
        DocumentSnapshot classDoc = await FirebaseFirestore.instance
            .collection('lop')
            .doc(assignment.idLop)
            .get();

        if (classDoc.exists) {
          Map<String, dynamic> classData =
              classDoc.data() as Map<String, dynamic>;
          classData['id'] = classDoc.id;

          classesWithInfo.add({
            'lop': classData,
            'assignment': assignment.toFirestore(),
            'assignmentId': assignment.id,
          });
        }
      }

      return classesWithInfo;
    } catch (e) {
      throw Exception('Failed to fetch teacher classes: $e');
    }
  }
}
