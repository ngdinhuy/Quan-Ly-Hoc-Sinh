import '../models/lop.dart';
import 'firebase_service.dart';

class LopService {
  static const String collection = 'lop';

  static Future<String> createLop(Lop lop) async {
    final docRef = await FirebaseService.firestore
        .collection(collection)
        .add(lop.toFirestore());
    return docRef.id;
  }

  static Future<void> updateLop(String id, Lop lop) async {
    await FirebaseService.firestore
        .collection(collection)
        .doc(id)
        .update(lop.toFirestore());
  }

  static Future<void> deleteLop(String id) async {
    await FirebaseService.firestore.collection(collection).doc(id).delete();
  }

  static Future<Lop?> getLopById(String id) async {
    final doc =
        await FirebaseService.firestore.collection(collection).doc(id).get();

    if (doc.exists) {
      return Lop.fromFirestore(doc);
    }
    return null;
  }

  static Future<List<Lop>> getLopByKhoi(String idKhoi) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('id_khoi', isEqualTo: idKhoi)
            .orderBy('created_at', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => Lop.fromFirestore(doc)).toList();
  }

  static Future<List<Lop>> getLopByTruong(String idTruong) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('id_truong', isEqualTo: idTruong)
            .orderBy('created_at', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => Lop.fromFirestore(doc)).toList();
  }

  static Stream<List<Lop>> streamLopByKhoi(String idKhoi) {
    return FirebaseService.firestore
        .collection(collection)
        .where('id_khoi', isEqualTo: idKhoi)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Lop.fromFirestore(doc)).toList(),
        );
  }

  static Stream<List<Lop>> streamLopByTruong(String idTruong) {
    return FirebaseService.firestore
        .collection(collection)
        .where('id_truong', isEqualTo: idTruong)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Lop.fromFirestore(doc)).toList(),
        );
  }

  static Future<List<Lop>> getAllLop() async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .orderBy('created_at', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => Lop.fromFirestore(doc)).toList();
  }
}
