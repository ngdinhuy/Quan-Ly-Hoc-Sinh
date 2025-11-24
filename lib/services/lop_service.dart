import '../models/lop.dart';
import 'firebase_service.dart';

// CaHocConfig is defined in lop.dart

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

  /// Update attendance config for a class
  static Future<void> updateAttendanceConfig(
    String idLop,
    Map<String, CaHocConfig> config,
  ) async {
    final configData = config.map(
      (key, value) => MapEntry(key, value.toMap()),
    );

    await FirebaseService.firestore.collection(collection).doc(idLop).update({
      'cau_hinh_diem_danh': configData,
    });
  }

  /// Get default attendance config for all 7 days
  static Map<String, CaHocConfig> getDefaultAttendanceConfig() {
    final defaultConfig = CaHocConfig.defaultConfig();
    return {
      '1': defaultConfig, // Monday
      '2': defaultConfig, // Tuesday
      '3': defaultConfig, // Wednesday
      '4': defaultConfig, // Thursday
      '5': defaultConfig, // Friday
      '6': defaultConfig, // Saturday
      '7': defaultConfig, // Sunday
    };
  }
}
