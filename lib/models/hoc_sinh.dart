import 'package:cloud_firestore/cloud_firestore.dart';

enum TrangThaiHocSinh { dangHoc, tamNghi, nghiHoc }

class HocSinh {
  final String? id;
  final String hoTen;
  final DateTime ngaySinh;
  final String soTheHocSinh;
  String matKhau = "123456";
  final String? soDienThoai;
  final String? diaChi;
  final String idLop;
  final String phongSo;
  final String? avatarTheUrl;
  final String? avatarFaceUrl;
  final TrangThaiHocSinh trangThai;
  final Map<String, dynamic>? thongTinKhac;
  final DateTime createdAt;

  HocSinh({
    this.id,
    required this.hoTen,
    required this.ngaySinh,
    required this.soTheHocSinh,
    this.matKhau = "123456",
    this.soDienThoai,
    this.diaChi,
    required this.idLop,
    required this.phongSo,
    this.avatarTheUrl,
    this.avatarFaceUrl,
    this.trangThai = TrangThaiHocSinh.dangHoc,
    this.thongTinKhac,
    required this.createdAt,
  });

  factory HocSinh.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HocSinh(
      id: doc.id,
      hoTen: data['ho_ten'] ?? '',
      ngaySinh: (data['ngay_sinh'] as Timestamp).toDate(),
      soTheHocSinh: data['so_the_hoc_sinh'] ?? '',
      matKhau: data['mat_khau'] ?? '',
      soDienThoai: data['so_dien_thoai'],
      diaChi: data['dia_chi'],
      idLop: data['id_lop'] ?? '',
      phongSo: data['phong_so'] ?? '',
      avatarTheUrl: data['avatar_the_url'],
      avatarFaceUrl: data['avatar_face_url'],
      trangThai: _parseTrangThai(data['trang_thai']),
      thongTinKhac:
          data['thong_tin_khac'] != null
              ? Map<String, dynamic>.from(data['thong_tin_khac'])
              : null,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  static TrangThaiHocSinh _parseTrangThai(String? status) {
    switch (status) {
      case 'tam_nghi':
        return TrangThaiHocSinh.tamNghi;
      case 'nghi_hoc':
        return TrangThaiHocSinh.nghiHoc;
      default:
        return TrangThaiHocSinh.dangHoc;
    }
  }

  String get trangThaiString {
    switch (trangThai) {
      case TrangThaiHocSinh.dangHoc:
        return 'dang_hoc';
      case TrangThaiHocSinh.tamNghi:
        return 'tam_nghi';
      case TrangThaiHocSinh.nghiHoc:
        return 'nghi_hoc';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ho_ten': hoTen,
      'ngay_sinh': Timestamp.fromDate(ngaySinh),
      'so_the_hoc_sinh': soTheHocSinh,
      'so_dien_thoai': soDienThoai,
      'dia_chi': diaChi,
      'id_lop': idLop,
      'phong_so': phongSo,
      'avatar_the_url': avatarTheUrl,
      'avatar_face_url': avatarFaceUrl,
      'trang_thai': trangThaiString,
      'thong_tin_khac': thongTinKhac,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  HocSinh copyWith({
    String? id,
    String? hoTen,
    DateTime? ngaySinh,
    String? soTheHocSinh,
    String? matKhau,
    String? soDienThoai,
    String? diaChi,
    String? idLop,
    String? phongSo,
    String? avatarTheUrl,
    String? avatarFaceUrl,
    TrangThaiHocSinh? trangThai,
    Map<String, dynamic>? thongTinKhac,
    DateTime? createdAt,
  }) {
    return HocSinh(
      id: id ?? this.id,
      hoTen: hoTen ?? this.hoTen,
      ngaySinh: ngaySinh ?? this.ngaySinh,
      soTheHocSinh: soTheHocSinh ?? this.soTheHocSinh,
      matKhau: matKhau ?? this.matKhau,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      diaChi: diaChi ?? this.diaChi,
      idLop: idLop ?? this.idLop,
      phongSo: phongSo ?? this.phongSo,
      avatarTheUrl: avatarTheUrl ?? this.avatarTheUrl,
      avatarFaceUrl: avatarFaceUrl ?? this.avatarFaceUrl,
      trangThai: trangThai ?? this.trangThai,
      thongTinKhac: thongTinKhac ?? this.thongTinKhac,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
