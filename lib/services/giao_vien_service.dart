import '../models/giao_vien.dart';
import 'firebase_service.dart';

class GiaoVienService {
  //
  // static final GiaoVienService _instance = GiaoVienService._internal();
  // // Private constructor
  // GiaoVienService._internal();
  // // Public getter for the singleton instance
  // static GiaoVienService get instance => _instance;

  static const String collection = 'giao_vien';

  static Future<String> createGiaoVien(GiaoVien giaoVien) async {
    final docRef = await FirebaseService.firestore
        .collection(collection)
        .add(giaoVien.toFirestore());
    return docRef.id;
  }

  static Future<void> updateGiaoVien(String id, GiaoVien giaoVien) async {
    await FirebaseService.firestore
        .collection(collection)
        .doc(id)
        .update(giaoVien.toFirestore());
  }

  static Future<void> deleteGiaoVien(String id) async {
    await FirebaseService.firestore.collection(collection).doc(id).delete();
  }

  static Future<GiaoVien?> getGiaoVienById(String id) async {
    final doc =
        await FirebaseService.firestore.collection(collection).doc(id).get();

    if (doc.exists) {
      return GiaoVien.fromFirestore(doc);
    }
    return null;
  }

  static Future<List<GiaoVien>> getAllGiaoVien() async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .orderBy('created_at', descending: true)
            .get();

    return querySnapshot.docs
        .map((doc) => GiaoVien.fromFirestore(doc))
        .toList();
  }

  static Stream<List<GiaoVien>> streamGiaoVien() {
    return FirebaseService.firestore
        .collection(collection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => GiaoVien.fromFirestore(doc)).toList(),
        );
  }

  static Future<List<GiaoVien>> searchGiaoVien(String query) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('ho_ten', isGreaterThanOrEqualTo: query)
            .where('ho_ten', isLessThan: query + 'z')
            .get();

    return querySnapshot.docs
        .map((doc) => GiaoVien.fromFirestore(doc))
        .toList();
  }

  static Future<GiaoVien?> getGiaoVienByIdUser(String idUser) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('id_user', isEqualTo: idUser)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      return GiaoVien.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }
}
