import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/phan_cong_truc_ban.dart';

class PhanCongTrucBanService {
  static final CollectionReference phanCongCollection =
      FirebaseFirestore.instance.collection('phan_cong_truc_ban');

  // Create a new duty assignment
  static Future<PhanCongTrucBan> create(PhanCongTrucBan phanCong) async {
    try {
      DocumentReference docRef = await phanCongCollection
          .add(phanCong.toFirestore());

      // Return the created assignment with the new ID
      return phanCong.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create duty assignment: $e');
    }
  }

  // Update an existing duty assignment
  static Future<void> update(PhanCongTrucBan phanCong) async {
    try {
      if (phanCong.id == null) {
        throw Exception('Cannot update duty assignment without an ID');
      }

      await phanCongCollection
          .doc(phanCong.id)
          .update(phanCong.toFirestore());
    } catch (e) {
      throw Exception('Failed to update duty assignment: $e');
    }
  }

  // Delete a duty assignment
  static Future<void> delete(String id) async {
    try {
      await phanCongCollection
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete duty assignment: $e');
    }
  }

  // Get duty assignment by ID
  static Future<PhanCongTrucBan?> getById(String id) async {
    try {
      DocumentSnapshot doc = await phanCongCollection
          .doc(id)
          .get();

      if (doc.exists) {
        return PhanCongTrucBan.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch duty assignment: $e');
    }
  }

  // Get all duty assignments
  static Future<List<PhanCongTrucBan>> getAll() async {
    try {
      QuerySnapshot snapshot = await phanCongCollection
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PhanCongTrucBan.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch duty assignments by teacher ID: $e');
      throw Exception('Failed to fetch duty assignments: $e');
    }
  }

  // Get duty assignments by school ID
  static Future<List<PhanCongTrucBan>> getBySchoolId(String idTruong) async {
    try {
      QuerySnapshot snapshot = await phanCongCollection
          .where('id_truong', isEqualTo: idTruong)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PhanCongTrucBan.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch duty assignments by teacher ID: $e');
      throw Exception('Failed to fetch duty assignments by school ID: $e');
    }
  }

  // Get duty assignments by teacher ID
  static Future<List<PhanCongTrucBan>> getByTeacherId(String idGiaoVien) async {
    try {
      QuerySnapshot snapshot = await phanCongCollection
          .where('id_giao_vien', isEqualTo: idGiaoVien)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PhanCongTrucBan.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch duty assignments by teacher ID: $e');
      throw Exception('Failed to fetch duty assignments by teacher ID: $e');
    }
  }

  // Get duty assignments for a specific date range
  static Future<List<PhanCongTrucBan>> getByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot snapshot = await phanCongCollection
          .orderBy('created_at', descending: true)
          .get();

      // Filter assignments that have duty dates within the range
      List<PhanCongTrucBan> result = [];
      for (var doc in snapshot.docs) {
        PhanCongTrucBan phanCong = PhanCongTrucBan.fromFirestore(doc);

        // Check if any duty date falls within the specified range
        bool hasDateInRange = phanCong.ngayTrucBan.any(
          (date) => (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
                   (date.isBefore(endDate) || date.isAtSameMomentAs(endDate))
        );

        if (hasDateInRange) {
          result.add(phanCong);
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch duty assignments by date range: $e');
    }
  }
}