import '../models/phu_huynh.dart';
import 'firebase_service.dart';

class PhuHuynhService {
  static const String collection = 'phu_huynh';

  static Future<String> createPhuHuynh(PhuHuynh phuHuynh) async {
    final docRef = await FirebaseService.firestore
        .collection(collection)
        .add(phuHuynh.toFirestore());
    return docRef.id;
  }

  static Future<void> updatePhuHuynh(String id, PhuHuynh phuHuynh) async {
    await FirebaseService.firestore
        .collection(collection)
        .doc(id)
        .update(phuHuynh.toFirestore());
  }

  static Future<void> deletePhuHuynh(String id) async {
    await FirebaseService.firestore.collection(collection).doc(id).delete();
  }

  static Future<PhuHuynh?> getPhuHuynhById(String id) async {
    final doc =
        await FirebaseService.firestore.collection(collection).doc(id).get();

    if (doc.exists) {
      return PhuHuynh.fromFirestore(doc);
    }
    return null;
  }

  static Future<List<PhuHuynh>> getPhuHuynhByHs(String idHs) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('id_hs', isEqualTo: idHs)
            .orderBy('created_at', descending: true)
            .get();

    return querySnapshot.docs
        .map((doc) => PhuHuynh.fromFirestore(doc))
        .toList();
  }

  static Future<PhuHuynh?> getPhuHuynhByCccd(String soCccd) async {
    final querySnapshot =
        await FirebaseService.firestore
            .collection(collection)
            .where('so_cccd', isEqualTo: soCccd)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      return PhuHuynh.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  static Stream<List<PhuHuynh>> streamPhuHuynhByHs(String idHs) {
    return FirebaseService.firestore
        .collection(collection)
        .where('id_hs', isEqualTo: idHs)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PhuHuynh.fromFirestore(doc)).toList(),
        );
  }
}
