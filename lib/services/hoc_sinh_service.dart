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

  static Future<HocSinh?> login(String id, String matKhau) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('id', isEqualTo: id)
            .where('mat_khau', isEqualTo: matKhau)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      return HocSinh.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }
}
