import '../models/truong.dart';
import 'firebase_service.dart';

class TruongService {
  static const String collection = 'truong';

  static Future<String> createTruong(Truong truong) async {
    final docRef = await FirebaseService.firestore
        .collection(collection)
        .add(truong.toFirestore());
    return docRef.id;
  }

  static Future<void> updateTruong(String id, Truong truong) async {
    await FirebaseService.firestore
        .collection(collection)
        .doc(id)
        .update(truong.toFirestore());
  }

  static Future<void> deleteTruong(String id) async {
    await FirebaseService.firestore.collection(collection).doc(id).delete();
  }

  static Future<Truong?> getTruongById(String id) async {
    final doc =
        await FirebaseService.firestore.collection(collection).doc(id).get();

    if (doc.exists) {
      return Truong.fromFirestore(doc);
    }
    return null;
  }

  static Future<List<Truong>> getAllTruong() async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .orderBy('created_at', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => Truong.fromFirestore(doc)).toList();
  }

  static Stream<List<Truong>> streamTruong() {
    return FirebaseService.firestore
        .collection(collection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Truong.fromFirestore(doc)).toList(),
        );
  }
}
