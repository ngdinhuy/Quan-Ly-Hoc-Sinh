import 'package:cloud_firestore/cloud_firestore.dart';

/// Attendance period enum
enum CaDiemDanh { sang, trua, chieuToi }

/// Attendance status enum
enum TrangThaiDiemDanh { dungGio, tre, vangPhep }

/// Authentication method for check-in
enum PhuongThucDiemDanh { the, khuonMat }

class DiemDanh {
  final String? id;
  final String idHocSinh;
  final String idLop;
  final DateTime ngay; // Date only (time at 00:00)
  final CaDiemDanh ca;
  final DateTime thoiGianCheckin;
  final PhuongThucDiemDanh phuongThuc;
  final TrangThaiDiemDanh trangThai;
  final String? ghiChu;
  final DateTime createdAt;

  DiemDanh({
    this.id,
    required this.idHocSinh,
    required this.idLop,
    required this.ngay,
    required this.ca,
    required this.thoiGianCheckin,
    required this.phuongThuc,
    required this.trangThai,
    this.ghiChu,
    required this.createdAt,
  });

  factory DiemDanh.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DiemDanh(
      id: doc.id,
      idHocSinh: data['id_hoc_sinh'] ?? '',
      idLop: data['id_lop'] ?? '',
      ngay: (data['ngay'] as Timestamp).toDate(),
      ca: _parseCa(data['ca']),
      thoiGianCheckin: (data['thoi_gian_checkin'] as Timestamp).toDate(),
      phuongThuc: _parsePhuongThuc(data['phuong_thuc']),
      trangThai: _parseTrangThai(data['trang_thai']),
      ghiChu: data['ghi_chu'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_hoc_sinh': idHocSinh,
      'id_lop': idLop,
      'ngay': Timestamp.fromDate(ngay),
      'ca': caToString(ca),
      'thoi_gian_checkin': Timestamp.fromDate(thoiGianCheckin),
      'phuong_thuc': phuongThucToString(phuongThuc),
      'trang_thai': trangThaiToString(trangThai),
      'ghi_chu': ghiChu,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  DiemDanh copyWith({
    String? id,
    String? idHocSinh,
    String? idLop,
    DateTime? ngay,
    CaDiemDanh? ca,
    DateTime? thoiGianCheckin,
    PhuongThucDiemDanh? phuongThuc,
    TrangThaiDiemDanh? trangThai,
    String? ghiChu,
    DateTime? createdAt,
  }) {
    return DiemDanh(
      id: id ?? this.id,
      idHocSinh: idHocSinh ?? this.idHocSinh,
      idLop: idLop ?? this.idLop,
      ngay: ngay ?? this.ngay,
      ca: ca ?? this.ca,
      thoiGianCheckin: thoiGianCheckin ?? this.thoiGianCheckin,
      phuongThuc: phuongThuc ?? this.phuongThuc,
      trangThai: trangThai ?? this.trangThai,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Parse helpers
  static CaDiemDanh _parseCa(String? value) {
    switch (value) {
      case 'sang':
        return CaDiemDanh.sang;
      case 'trua':
        return CaDiemDanh.trua;
      case 'chieu_toi':
        return CaDiemDanh.chieuToi;
      default:
        return CaDiemDanh.sang;
    }
  }

  static TrangThaiDiemDanh _parseTrangThai(String? value) {
    switch (value) {
      case 'dung_gio':
        return TrangThaiDiemDanh.dungGio;
      case 'tre':
        return TrangThaiDiemDanh.tre;
      case 'vang_phep':
        return TrangThaiDiemDanh.vangPhep;
      default:
        return TrangThaiDiemDanh.dungGio;
    }
  }

  static PhuongThucDiemDanh _parsePhuongThuc(String? value) {
    switch (value) {
      case 'the':
        return PhuongThucDiemDanh.the;
      case 'khuon_mat':
        return PhuongThucDiemDanh.khuonMat;
      default:
        return PhuongThucDiemDanh.the;
    }
  }

  // To string helpers
  static String caToString(CaDiemDanh ca) {
    switch (ca) {
      case CaDiemDanh.sang:
        return 'sang';
      case CaDiemDanh.trua:
        return 'trua';
      case CaDiemDanh.chieuToi:
        return 'chieu_toi';
    }
  }

  static String trangThaiToString(TrangThaiDiemDanh trangThai) {
    switch (trangThai) {
      case TrangThaiDiemDanh.dungGio:
        return 'dung_gio';
      case TrangThaiDiemDanh.tre:
        return 'tre';
      case TrangThaiDiemDanh.vangPhep:
        return 'vang_phep';
    }
  }

  static String phuongThucToString(PhuongThucDiemDanh phuongThuc) {
    switch (phuongThuc) {
      case PhuongThucDiemDanh.the:
        return 'the';
      case PhuongThucDiemDanh.khuonMat:
        return 'khuon_mat';
    }
  }

  // Display helpers
  String get caDisplayName {
    switch (ca) {
      case CaDiemDanh.sang:
        return 'Sáng';
      case CaDiemDanh.trua:
        return 'Trưa';
      case CaDiemDanh.chieuToi:
        return 'Chiều tối';
    }
  }

  String get trangThaiDisplayName {
    switch (trangThai) {
      case TrangThaiDiemDanh.dungGio:
        return 'Đúng giờ';
      case TrangThaiDiemDanh.tre:
        return 'Trễ';
      case TrangThaiDiemDanh.vangPhep:
        return 'Vắng phép';
    }
  }

  String get phuongThucDisplayName {
    switch (phuongThuc) {
      case PhuongThucDiemDanh.the:
        return 'Thẻ';
      case PhuongThucDiemDanh.khuonMat:
        return 'Khuôn mặt';
    }
  }
}
