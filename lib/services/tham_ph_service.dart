import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tham_ph.dart';
import 'firebase_service.dart';

class ThamPhService {
  static const String collection = 'tham_ph';

  static Future<String> createThamPh(ThamPh thamPh) async {
    final docRef = await FirebaseService.firestore
        .collection(collection)
        .add(thamPh.toFirestore());
    return docRef.id;
  }

  static Future<void> updateThamPh(String id, ThamPh thamPh) async {
    await FirebaseService.firestore
        .collection(collection)
        .doc(id)
        .update(thamPh.toFirestore());
  }

  static Future<void> deleteThamPh(String id) async {
    await FirebaseService.firestore.collection(collection).doc(id).delete();
  }

  static Future<ThamPh?> getThamPhById(String id) async {
    final doc =
        await FirebaseService.firestore.collection(collection).doc(id).get();

    if (doc.exists) {
      return ThamPh.fromFirestore(doc);
    }
    return null;
  }

  static Future<List<ThamPh>> getThamPhByHs(String idHs) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('id_hs', isEqualTo: idHs)
            .orderBy('thoi_gian_den', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => ThamPh.fromFirestore(doc)).toList();
  }

  static Future<List<ThamPh>> getThamPhByTrangThai(
    TrangThaiTham trangThai,
  ) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('trang_thai', isEqualTo: _getTrangThaiString(trangThai))
            .orderBy('thoi_gian_den', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => ThamPh.fromFirestore(doc)).toList();
  }

  static Future<List<ThamPh>> getThamPhByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where(
              'thoi_gian_den',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'thoi_gian_den',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .orderBy('thoi_gian_den', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => ThamPh.fromFirestore(doc)).toList();
  }

  static Stream<List<ThamPh>> streamThamPhByHs(String idHs) {
    return FirebaseService.firestore
        .collection(collection)
        .where('id_hs', isEqualTo: idHs)
        .orderBy('thoi_gian_den', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ThamPh.fromFirestore(doc)).toList(),
        );
  }

  static Stream<List<ThamPh>> streamThamPhByTrangThai(TrangThaiTham trangThai) {
    return FirebaseService.firestore
        .collection(collection)
        .where('trang_thai', isEqualTo: _getTrangThaiString(trangThai))
        .orderBy('thoi_gian_den', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ThamPh.fromFirestore(doc)).toList(),
        );
  }

  static String _getTrangThaiString(TrangThaiTham trangThai) {
    switch (trangThai) {
      case TrangThaiTham.dangTham:
        return 'dang_tham';
      case TrangThaiTham.daVe:
        return 'da_ve';
    }
  }
}
