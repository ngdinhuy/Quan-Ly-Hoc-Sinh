import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/xin_ra_vao.dart';
import 'firebase_service.dart';

class XinRaVaoService {
  static const String collection = 'xin_ra_vao';

  static Future<String> createXinRaVao(XinRaVao xinRaVao) async {
    final docRef = await FirebaseService.firestore
        .collection(collection)
        .add(xinRaVao.toFirestore());
    return docRef.id;
  }

  static Future<void> updateXinRaVao(String id, XinRaVao xinRaVao) async {
    await FirebaseService.firestore
        .collection(collection)
        .doc(id)
        .update(xinRaVao.toFirestore());
  }

  static Future<void> deleteXinRaVao(String id) async {
    await FirebaseService.firestore.collection(collection).doc(id).delete();
  }

  static Future<XinRaVao?> getXinRaVaoById(String id) async {
    final doc =
        await FirebaseService.firestore.collection(collection).doc(id).get();

    if (doc.exists) {
      return XinRaVao.fromFirestore(doc);
    }
    return null;
  }

  static Future<List<XinRaVao>> getXinRaVaoByLop(String idLop) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('id_lop', isEqualTo: idLop)
            .orderBy('created_at', descending: true)
            .get();

    return querySnapshot.docs
        .map((doc) => XinRaVao.fromFirestore(doc))
        .toList();
  }

  static Future<List<XinRaVao>> getXinRaVaoByHs(String idHs) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('id_hs', isEqualTo: idHs)
            .orderBy('created_at', descending: true)
            .get();

    return querySnapshot.docs
        .map((doc) => XinRaVao.fromFirestore(doc))
        .toList();
  }

  static Future<List<XinRaVao>> getXinRaVaoByTrangThai(
    TrangThaiXin trangThai,
  ) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('trang_thai', isEqualTo: _getTrangThaiString(trangThai))
            .orderBy('created_at', descending: true)
            .get();

    return querySnapshot.docs
        .map((doc) => XinRaVao.fromFirestore(doc))
        .toList();
  }

  static Stream<List<XinRaVao>> streamXinRaVaoByLop(String idLop) {
    return FirebaseService.firestore
        .collection(collection)
        .where('id_lop', isEqualTo: idLop)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => XinRaVao.fromFirestore(doc)).toList(),
        );
  }

  static Stream<List<XinRaVao>> streamXinRaVaoByTrangThai(
    TrangThaiXin trangThai,
  ) {
    return FirebaseService.firestore
        .collection(collection)
        .where('trang_thai', isEqualTo: _getTrangThaiString(trangThai))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => XinRaVao.fromFirestore(doc)).toList(),
        );
  }

  static Future<List<XinRaVao>> getXinRaVaoByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where(
              'thoi_gian_xin',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'thoi_gian_xin',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .orderBy('thoi_gian_xin', descending: true)
            .get();

    return querySnapshot.docs
        .map((doc) => XinRaVao.fromFirestore(doc))
        .toList();
  }

  static String _getTrangThaiString(TrangThaiXin trangThai) {
    switch (trangThai) {
      case TrangThaiXin.choDuyet:
        return 'cho_duyet';
      case TrangThaiXin.daDuyet:
        return 'da_duyet';
      case TrangThaiXin.daVao:
        return 'da_vao';
      case TrangThaiXin.tuChoi:
        return 'tu_choi';
    }
  }

  static Future<List<XinRaVao>> filterXinRaVaoByIdHs({
    required String idHs,
    TrangThaiXin? trangThai,
    LoaiXin? loai,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    Query query = FirebaseService.firestore
        .collection(collection)
        .where('id_hs', isEqualTo: idHs);

    // Filter by request status if provided
    if (trangThai != null) {
      query = query.where('trang_thai', isEqualTo: _getTrangThaiString(trangThai));
    }

    // Filter by request type if provided
    if (loai != null) {
      String loaiString;
      switch (loai) {
        case LoaiXin.xinRa:
          loaiString = 'xin_ra';
          break;
        case LoaiXin.vaoLai:
          loaiString = 'vao_lai';
          break;
        case LoaiXin.tamNghi:
          loaiString = 'tam_nghi';
          break;
      }
      query = query.where('loai', isEqualTo: loaiString);
    }

    // Add date range filter if provided
    if (fromDate != null && toDate != null) {
      query = query.where('thoi_gian_xin',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
          .where('thoi_gian_xin',
          isLessThanOrEqualTo: Timestamp.fromDate(toDate));
    }

    // Order by created time in descending order
    query = query.orderBy('created_at', descending: true);
    final querySnapshot = await query.get();

    return querySnapshot.docs
        .map((doc) => XinRaVao.fromFirestore(doc))
        .toList();
  }

}
