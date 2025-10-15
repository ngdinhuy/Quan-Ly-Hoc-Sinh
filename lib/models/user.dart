import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, giaovien, hocsinh }

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastLogin;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    required this.lastLogin,
    this.metadata,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'role': _getRoleString(role),
      'created_at': Timestamp.fromDate(createdAt),
      'last_login': Timestamp.fromDate(lastLogin),
      'metadata': metadata ?? {},
    };
  }

  static UserModel fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['display_name'] ?? '',
      photoUrl: data['photo_url'],
      role: _getRoleFromString(data['role'] ?? 'hocsinh'),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      lastLogin: (data['last_login'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  static String _getRoleString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.giaovien:
        return 'giaovien';
      case UserRole.hocsinh:
        return 'hocsinh';
    }
  }

  static UserRole _getRoleFromString(String roleString) {
    switch (roleString) {
      case 'admin':
        return UserRole.admin;
      case 'giaovien':
        return UserRole.giaovien;
      case 'hocsinh':
        return UserRole.hocsinh;
      default:
        return UserRole.hocsinh;
    }
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      metadata: metadata ?? this.metadata,
    );
  }
}
