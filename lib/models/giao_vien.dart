import 'package:cloud_firestore/cloud_firestore.dart';

class GiaoVien {
  final String? id;
  String idUser = "";
  final String hoTen;
  final String soDienThoai;
  final String? email;
  final String? cmndCccd;
  final DateTime? ngaySinh;
  final String? avatarUrl;
  final String? chucVu;
  final List<String> roles;
  final DateTime createdAt;

  GiaoVien({
    this.id,
    this.idUser = "",
    required this.hoTen,
    required this.soDienThoai,
    this.email,
    this.cmndCccd,
    this.ngaySinh,
    this.avatarUrl,
    this.chucVu,
    this.roles = const ['giaovien'],
    required this.createdAt,
  });

  factory GiaoVien.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GiaoVien(
      id: doc.id,
      idUser: data['id_user'] ?? '',
      hoTen: data['ho_ten'] ?? '',
      soDienThoai: data['so_dien_thoai'] ?? '',
      email: data['email'],
      cmndCccd: data['cmnd_cccd'],
      ngaySinh:
          data['ngay_sinh'] != null
              ? (data['ngay_sinh'] as Timestamp).toDate()
              : null,
      avatarUrl: data['avatar_url'],
      chucVu: data['chuc_vu'],
      roles: List<String>.from(data['roles'] ?? ['giaovien']),
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_user': idUser,
      'ho_ten': hoTen,
      'so_dien_thoai': soDienThoai,
      'email': email,
      'cmnd_cccd': cmndCccd,
      'ngay_sinh': ngaySinh != null ? Timestamp.fromDate(ngaySinh!) : null,
      'avatar_url': avatarUrl,
      'chuc_vu': chucVu,
      'roles': roles,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  GiaoVien copyWith({
    String? id,
    String? idUser,
    String? hoTen,
    String? soDienThoai,
    String? email,
    String? cmndCccd,
    DateTime? ngaySinh,
    String? avatarUrl,
    String? chucVu,
    List<String>? roles,
    DateTime? createdAt,
  }) {
    return GiaoVien(
      id: id ?? this.id,
      idUser: idUser ?? this.idUser,
      hoTen: hoTen ?? this.hoTen,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      email: email ?? this.email,
      cmndCccd: cmndCccd ?? this.cmndCccd,
      ngaySinh: ngaySinh ?? this.ngaySinh,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      chucVu: chucVu ?? this.chucVu,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
