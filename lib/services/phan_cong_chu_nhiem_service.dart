import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quan_ly_hoc_sinh/models/phan_cong_chu_nhiem.dart';

class PhanCongChuNhiemService {
  final CollectionReference phanCongCollection =
  FirebaseFirestore.instance.collection('phan_cong_chu_nhiem');

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
}
