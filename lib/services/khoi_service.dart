import '../models/khoi.dart';
import 'firebase_service.dart';

class KhoiService {
  static const String collection = 'khoi';

  static Future<String> createKhoi(Khoi khoi) async {
    final docRef = await FirebaseService.firestore
        .collection(collection)
        .add(khoi.toFirestore());
    return docRef.id;
  }

  static Future<void> updateKhoi(String id, Khoi khoi) async {
    await FirebaseService.firestore
        .collection(collection)
        .doc(id)
        .update(khoi.toFirestore());
  }

  static Future<void> deleteKhoi(String id) async {
    await FirebaseService.firestore.collection(collection).doc(id).delete();
  }

  static Future<Khoi?> getKhoiById(String id) async {
    final doc =
        await FirebaseService.firestore.collection(collection).doc(id).get();

    if (doc.exists) {
      return Khoi.fromFirestore(doc);
    }
    return null;
  }

  static Future<List<Khoi>> getKhoiByTruong(String idTruong) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('id_truong', isEqualTo: idTruong)
            .orderBy('created_at', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => Khoi.fromFirestore(doc)).toList();
  }

  static Stream<List<Khoi>> streamKhoiByTruong(String idTruong) {
    return FirebaseService.firestore
        .collection(collection)
        .where('id_truong', isEqualTo: idTruong)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Khoi.fromFirestore(doc)).toList(),
        );
  }
}
