import 'package:cloud_firestore/cloud_firestore.dart';

enum TrangThaiTham { dangTham, daVe }

class ThamPh {
  final String? id;
  final String idPh;
  final String hoTenPh;
  final String soCccd;
  final String soDienThoai;
  final String idHs;
  final String hoTenHs;
  final String phongSo;
  final DateTime thoiGianDen;
  final DateTime? thoiGianKetThuc;
  final TrangThaiTham trangThai;
  final String? checkinFaceId;
  final DateTime createdAt;

  ThamPh({
    this.id,
    required this.idPh,
    required this.hoTenPh,
    required this.soCccd,
    required this.soDienThoai,
    required this.idHs,
    required this.hoTenHs,
    required this.phongSo,
    required this.thoiGianDen,
    this.thoiGianKetThuc,
    this.trangThai = TrangThaiTham.dangTham,
    this.checkinFaceId,
    required this.createdAt,
  });

  factory ThamPh.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ThamPh(
      id: doc.id,
      idPh: data['id_ph'] ?? '',
      hoTenPh: data['ho_ten_ph'] ?? '',
      soCccd: data['so_cccd'] ?? '',
      soDienThoai: data['so_dien_thoai'] ?? '',
      idHs: data['id_hs'] ?? '',
      hoTenHs: data['ho_ten_hs'] ?? '',
      phongSo: data['phong_so'] ?? '',
      thoiGianDen: (data['thoi_gian_den'] as Timestamp).toDate(),
      thoiGianKetThuc:
          data['thoi_gian_ket_thuc'] != null
              ? (data['thoi_gian_ket_thuc'] as Timestamp).toDate()
              : null,
      trangThai: _parseTrangThai(data['trang_thai']),
      checkinFaceId: data['checkin_face_id'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  static TrangThaiTham _parseTrangThai(String? status) {
    switch (status) {
      case 'da_ve':
        return TrangThaiTham.daVe;
      default:
        return TrangThaiTham.dangTham;
    }
  }

  String get trangThaiString {
    switch (trangThai) {
      case TrangThaiTham.dangTham:
        return 'dang_tham';
      case TrangThaiTham.daVe:
        return 'da_ve';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_ph': idPh,
      'ho_ten_ph': hoTenPh,
      'so_cccd': soCccd,
      'so_dien_thoai': soDienThoai,
      'id_hs': idHs,
      'ho_ten_hs': hoTenHs,
      'phong_so': phongSo,
      'thoi_gian_den': Timestamp.fromDate(thoiGianDen),
      'thoi_gian_ket_thuc':
          thoiGianKetThuc != null ? Timestamp.fromDate(thoiGianKetThuc!) : null,
      'trang_thai': trangThaiString,
      'checkin_face_id': checkinFaceId,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  ThamPh copyWith({
    String? id,
    String? idPh,
    String? hoTenPh,
    String? soCccd,
    String? soDienThoai,
    String? idHs,
    String? hoTenHs,
    String? phongSo,
    DateTime? thoiGianDen,
    DateTime? thoiGianKetThuc,
    TrangThaiTham? trangThai,
    String? checkinFaceId,
    DateTime? createdAt,
  }) {
    return ThamPh(
      id: id ?? this.id,
      idPh: idPh ?? this.idPh,
      hoTenPh: hoTenPh ?? this.hoTenPh,
      soCccd: soCccd ?? this.soCccd,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      idHs: idHs ?? this.idHs,
      hoTenHs: hoTenHs ?? this.hoTenHs,
      phongSo: phongSo ?? this.phongSo,
      thoiGianDen: thoiGianDen ?? this.thoiGianDen,
      thoiGianKetThuc: thoiGianKetThuc ?? this.thoiGianKetThuc,
      trangThai: trangThai ?? this.trangThai,
      checkinFaceId: checkinFaceId ?? this.checkinFaceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
