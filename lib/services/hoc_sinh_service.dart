import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hoc_sinh.dart';
import 'firebase_service.dart';

class HocSinhService {
  static const String collection = 'hoc_sinh';

  static Future<String> createHocSinh(HocSinh hocSinh) async {
    final docRef = await FirebaseService.firestore
        .collection(collection)
        .add(hocSinh.toFirestore());
    return docRef.id;
  }

  static Future<void> updateHocSinh(String id, HocSinh hocSinh) async {
    await FirebaseService.firestore
        .collection(collection)
        .doc(id)
        .update(hocSinh.toFirestore());
  }

  static Future<void> deleteHocSinh(String id) async {
    await FirebaseService.firestore.collection(collection).doc(id).delete();
  }

  static Future<HocSinh?> getHocSinhById(String id) async {
    final doc =
        await FirebaseService.firestore.collection(collection).doc(id).get();

    if (doc.exists) {
      return HocSinh.fromFirestore(doc);
    }
    return null;
  }

  static Future<HocSinh?> getHocSinhBySoThe(String soThe) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('so_the_hoc_sinh', isEqualTo: soThe)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      return HocSinh.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  static Future<List<HocSinh>> getHocSinhByLop(String idLop) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('id_lop', isEqualTo: idLop)
            .orderBy('ho_ten')
            .get();

    return querySnapshot.docs.map((doc) => HocSinh.fromFirestore(doc)).toList();
  }

  static Future<List<HocSinh>> getHocSinhByTruong(String idTruong) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('id_truong', isEqualTo: idTruong)
            .orderBy('ho_ten')
            .get();

    return querySnapshot.docs.map((doc) => HocSinh.fromFirestore(doc)).toList();
  }

  static Stream<List<HocSinh>> streamHocSinhByLop(String idLop) {
    return FirebaseService.firestore
        .collection(collection)
        .where('id_lop', isEqualTo: idLop)
        .orderBy('ho_ten')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => HocSinh.fromFirestore(doc)).toList(),
        );
  }

  static Future<List<HocSinh>> searchHocSinh(String query) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('ho_ten', isGreaterThanOrEqualTo: query)
            .where('ho_ten', isLessThan: query + 'z')
            .get();

    return querySnapshot.docs.map((doc) => HocSinh.fromFirestore(doc)).toList();
  }

  static Future<HocSinh?> getHocSinhByIdUser(String idUser) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('id_user', isEqualTo: idUser)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      return HocSinh.fromFirestore(querySnapshot.docs.first);
    } 
    return null;
  }

  static Future<HocSinh?> login(String soThe, String matKhau) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('so_the_hoc_sinh', isEqualTo: soThe)
            .where('mat_khau', isEqualTo: matKhau)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      return HocSinh.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  static Future<List<HocSinh>> getHocSinhByPhuHuynh(String phuHuynhId) async {
    // Lấy danh sách học sinh từ phụ huynh thông qua bảng phu_huynh
    final phuHuynhQuerySnapshot = await FirebaseService.firestore
        .collection('phu_huynh')
        .where(FieldPath.documentId, isEqualTo: phuHuynhId)
        .get();

    if (phuHuynhQuerySnapshot.docs.isEmpty) {
      return [];
    }

    final phuHuynhDoc = phuHuynhQuerySnapshot.docs.first;
    final phuHuynhData = phuHuynhDoc.data();
    final idHs = phuHuynhData['id_hs'] as String?;

    if (idHs == null) {
      return [];
    }

    // Lấy thông tin học sinh
    final hocSinhDoc = await FirebaseService.firestore
        .collection(collection)
        .doc(idHs)
        .get();

    if (hocSinhDoc.exists) {
      return [HocSinh.fromFirestore(hocSinhDoc)];
    }

    return [];
  }
}
