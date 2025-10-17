import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quan_ly_hoc_sinh/services/local_data_service.dart';
import '../models/user.dart' as app_user;
import 'firebase_service.dart';
import '../config/google_signin_config.dart';

class UserService {
  static const String collection = 'users';
  static const String adminEmails = 'admin_emails';

  static Future<app_user.UserModel?> getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc =
        await FirebaseService.firestore
            .collection(collection)
            .doc(user.uid)
            .get();

    if (doc.exists) {
      return app_user.UserModel.fromFirestore(doc);
    }
    return null;
  }

  static Future<app_user.UserModel> signInWithGoogle() async {
    UserCredential userCredential;

    if (kIsWeb) {
      // ✅ Web (FedCM-compliant popup)
      userCredential =
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } else {
      // ✅ Android / iOS
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
    }

    final User? firebaseUser = userCredential.user;
    debugPrint("HuyND Firebase User Credential: $firebaseUser");
    if (firebaseUser == null) {
      throw Exception('Failed to sign in with Google');
    }

    // Check if user exists in Firestore
    final doc =
        await FirebaseService.firestore
            .collection(collection)
            .doc(firebaseUser.uid)
            .get();

    if (doc.exists) {
      // Update last login
      await FirebaseService.firestore
          .collection(collection)
          .doc(firebaseUser.uid)
          .update({'last_login': Timestamp.fromDate(DateTime.now())});
      await _determineUserRole(firebaseUser.email ?? '');
      return app_user.UserModel.fromFirestore(doc);
    } else {
      // Create new user
      final role = await _determineUserRole(firebaseUser.email ?? '');
      final newUser = app_user.UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL,
        role: role,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await FirebaseService.firestore
          .collection(collection)
          .doc(firebaseUser.uid)
          .set(newUser.toFirestore());

      return newUser;
    }
  }

  static Future<app_user.UserRole> _determineUserRole(String email) async {
    // Check if email is in admin list
    final adminDoc =
        await FirebaseService.firestore
            .collection(adminEmails)
            .doc('list')
            .get();

    if (adminDoc.exists) {
      final adminEmails = List<String>.from(adminDoc.data()?['emails'] ?? []);
      LocalDataService.instance.saveRole(app_user.UserRole.admin);
      if (adminEmails.contains(email)) {
        return app_user.UserRole.admin;
      }
    }

    // Check if email matches a teacher
    final teacherQuery =
        await FirebaseService.firestore
            .collection('giao_vien')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
    debugPrint("HuyND Teacher Query Docs: ${teacherQuery.docs.first.id}");
    if (teacherQuery.docs.isNotEmpty) {
      LocalDataService.instance.saveRole(app_user.UserRole.giaovien);
      LocalDataService.instance.saveId(teacherQuery.docs.first.id);
      return app_user.UserRole.giaovien;
    }

    // Check if email matches a student
    final studentQuery =
        await FirebaseService.firestore
            .collection('hoc_sinh')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

    if (studentQuery.docs.isNotEmpty) {
      LocalDataService.instance.saveRole(app_user.UserRole.hocsinh);
      LocalDataService.instance.saveId(studentQuery.docs.first.id);
      return app_user.UserRole.hocsinh;
    }

    // Check if email matches a parent
    final parentQuery =
        await FirebaseService.firestore
            .collection('phu_huynh')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
    if (parentQuery.docs.isNotEmpty) {
      LocalDataService.instance.saveRole(app_user.UserRole.phuhuynh);
      LocalDataService.instance.saveId(parentQuery.docs.first.id);
      return app_user.UserRole.phuhuynh;
    }

    // Default role
    return app_user.UserRole.hocsinh;
  }

  static Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }

  static Future<void> updateUserRole(
    String userId,
    app_user.UserRole newRole,
  ) async {
    await FirebaseService.firestore.collection(collection).doc(userId).update({
      'role': _getRoleString(newRole),
    });
  }

  static Future<void> addAdminEmail(String email) async {
    await FirebaseService.firestore.collection(adminEmails).doc('list').set({
      'emails': FieldValue.arrayUnion([email]),
    }, SetOptions(merge: true));
  }

  static Future<void> removeAdminEmail(String email) async {
    await FirebaseService.firestore.collection(adminEmails).doc('list').update({
      'emails': FieldValue.arrayRemove([email]),
    });
  }

  static Future<List<String>> getAdminEmails() async {
    final doc =
        await FirebaseService.firestore
            .collection(adminEmails)
            .doc('list')
            .get();

    if (doc.exists) {
      return List<String>.from(doc.data()?['emails'] ?? []);
    }
    return [];
  }

  static String _getRoleString(app_user.UserRole role) {
    switch (role) {
      case app_user.UserRole.admin:
        return 'admin';
      case app_user.UserRole.giaovien:
        return 'giaovien';
      case app_user.UserRole.hocsinh:
        return 'hocsinh';
      case app_user.UserRole.phuhuynh:
        return 'phuhuynh';
    }
  }
}
