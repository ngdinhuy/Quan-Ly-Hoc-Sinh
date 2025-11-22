import 'package:cloud_firestore/cloud_firestore.dart';

enum TrangThaiVePhep {
  choDuyet, // Waiting for teacher approval (duty or homeroom)
  daDuyet, // Approved by teacher
  daVeTruong, // Student returned to school
  tuChoi, // Rejected by teacher
}

enum NguonVePhep {
  appHocSinh, // From student app
  appPhuHuynh, // From parent app
  giaoVienNhap, // Manually entered by teacher
}

class XinVePhep {
  // Identity & Basic Info
  final String? id;
  final String idHocSinh;
  final String hoTenHocSinh;
  final String soTheHocSinh;
  final String idLop;
  final String tenLop;

  // Parent Information (optional, only if submitted by parent)
  final String? idPhuHuynh;
  final String? tenPhuHuynh;

  // Leave Details
  final String lyDo;
  final DateTime thoiGianXinVe;
  final DateTime ngayXinVe;
  final DateTime? thoiGianXuongTruong;
  final DateTime? ngayXuongTruong;

  // Guardian Pickup Information
  final String tenNguoiDon;
  final String cccdNguoiDon;
  final String sdtNguoiDon;

  // Meal Deduction
  final List<DateTime> danhSachNgayCatCom;

  // Single Approval
  final String? idNguoiDuyet;
  final String? tenNguoiDuyet;
  final DateTime? thoiGianDuyet;

  // Status & Metadata
  final TrangThaiVePhep trangThai;
  final NguonVePhep nguon;
  final String? lyDoTuChoi;
  final DateTime createdAt;
  final DateTime? updatedAt;

  XinVePhep({
    this.id,
    required this.idHocSinh,
    required this.hoTenHocSinh,
    required this.soTheHocSinh,
    required this.idLop,
    required this.tenLop,
    this.idPhuHuynh,
    this.tenPhuHuynh,
    required this.lyDo,
    required this.thoiGianXinVe,
    required this.ngayXinVe,
    this.thoiGianXuongTruong,
    this.ngayXuongTruong,
    required this.tenNguoiDon,
    required this.cccdNguoiDon,
    required this.sdtNguoiDon,
    this.danhSachNgayCatCom = const [],
    this.idNguoiDuyet,
    this.tenNguoiDuyet,
    this.thoiGianDuyet,
    this.trangThai = TrangThaiVePhep.choDuyet,
    required this.nguon,
    this.lyDoTuChoi,
    required this.createdAt,
    this.updatedAt,
  });

  factory XinVePhep.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse meal deduction dates
    List<DateTime> mealDates = [];
    if (data['danh_sach_ngay_cat_com'] != null) {
      final List<dynamic> dates =
          data['danh_sach_ngay_cat_com'] as List<dynamic>;
      mealDates = dates.map((e) => (e as Timestamp).toDate()).toList();
    }

    return XinVePhep(
      id: doc.id,
      idHocSinh: data['id_hoc_sinh'] ?? '',
      hoTenHocSinh: data['ho_ten_hoc_sinh'] ?? '',
      soTheHocSinh: data['so_the_hoc_sinh'] ?? '',
      idLop: data['id_lop'] ?? '',
      tenLop: data['ten_lop'] ?? '',
      idPhuHuynh: data['id_phu_huynh'],
      tenPhuHuynh: data['ten_phu_huynh'],
      lyDo: data['ly_do'] ?? '',
      thoiGianXinVe: (data['thoi_gian_xin_ve'] as Timestamp).toDate(),
      ngayXinVe: (data['ngay_xin_ve'] as Timestamp).toDate(),
      thoiGianXuongTruong: data['thoi_gian_xuong_truong'] != null
          ? (data['thoi_gian_xuong_truong'] as Timestamp).toDate()
          : null,
      ngayXuongTruong: data['ngay_xuong_truong'] != null
          ? (data['ngay_xuong_truong'] as Timestamp).toDate()
          : null,
      tenNguoiDon: data['ten_nguoi_don'] ?? '',
      cccdNguoiDon: data['cccd_nguoi_don'] ?? '',
      sdtNguoiDon: data['sdt_nguoi_don'] ?? '',
      danhSachNgayCatCom: mealDates,
      idNguoiDuyet: data['id_nguoi_duyet'],
      tenNguoiDuyet: data['ten_nguoi_duyet'],
      thoiGianDuyet: data['thoi_gian_duyet'] != null
          ? (data['thoi_gian_duyet'] as Timestamp).toDate()
          : null,
      trangThai: _parseTrangThai(data['trang_thai']),
      nguon: _parseNguon(data['nguon']),
      lyDoTuChoi: data['ly_do_tu_choi'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
    );
  }

  static TrangThaiVePhep _parseTrangThai(String? status) {
    switch (status) {
      case 'da_duyet':
        return TrangThaiVePhep.daDuyet;
      case 'da_ve_truong':
        return TrangThaiVePhep.daVeTruong;
      case 'tu_choi':
        return TrangThaiVePhep.tuChoi;
      default:
        return TrangThaiVePhep.choDuyet;
    }
  }

  static NguonVePhep _parseNguon(String? nguon) {
    switch (nguon) {
      case 'app_phu_huynh':
        return NguonVePhep.appPhuHuynh;
      case 'app_hoc_sinh':
        return NguonVePhep.appHocSinh;
      case 'giao_vien_nhap':
        return NguonVePhep.giaoVienNhap;
      default:
        return NguonVePhep.appHocSinh;
    }
  }

  String get trangThaiString {
    switch (trangThai) {
      case TrangThaiVePhep.choDuyet:
        return 'cho_duyet';
      case TrangThaiVePhep.daDuyet:
        return 'da_duyet';
      case TrangThaiVePhep.daVeTruong:
        return 'da_ve_truong';
      case TrangThaiVePhep.tuChoi:
        return 'tu_choi';
    }
  }

  String get nguonString {
    switch (nguon) {
      case NguonVePhep.appHocSinh:
        return 'app_hoc_sinh';
      case NguonVePhep.appPhuHuynh:
        return 'app_phu_huynh';
      case NguonVePhep.giaoVienNhap:
        return 'giao_vien_nhap';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_hoc_sinh': idHocSinh,
      'ho_ten_hoc_sinh': hoTenHocSinh,
      'so_the_hoc_sinh': soTheHocSinh,
      'id_lop': idLop,
      'ten_lop': tenLop,
      'id_phu_huynh': idPhuHuynh,
      'ten_phu_huynh': tenPhuHuynh,
      'ly_do': lyDo,
      'thoi_gian_xin_ve': Timestamp.fromDate(thoiGianXinVe),
      'ngay_xin_ve': Timestamp.fromDate(ngayXinVe),
      'thoi_gian_xuong_truong': thoiGianXuongTruong != null
          ? Timestamp.fromDate(thoiGianXuongTruong!)
          : null,
      'ngay_xuong_truong': ngayXuongTruong != null
          ? Timestamp.fromDate(ngayXuongTruong!)
          : null,
      'ten_nguoi_don': tenNguoiDon,
      'cccd_nguoi_don': cccdNguoiDon,
      'sdt_nguoi_don': sdtNguoiDon,
      'danh_sach_ngay_cat_com': danhSachNgayCatCom.map((date) {
        // Store dates only (without time)
        final dateOnly = DateTime(date.year, date.month, date.day);
        return Timestamp.fromDate(dateOnly);
      }).toList(),
      'id_nguoi_duyet': idNguoiDuyet,
      'ten_nguoi_duyet': tenNguoiDuyet,
      'thoi_gian_duyet': thoiGianDuyet != null
          ? Timestamp.fromDate(thoiGianDuyet!)
          : null,
      'trang_thai': trangThaiString,
      'nguon': nguonString,
      'ly_do_tu_choi': lyDoTuChoi,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  XinVePhep copyWith({
    String? id,
    String? idHocSinh,
    String? hoTenHocSinh,
    String? soTheHocSinh,
    String? idLop,
    String? tenLop,
    String? idPhuHuynh,
    String? tenPhuHuynh,
    String? lyDo,
    DateTime? thoiGianXinVe,
    DateTime? ngayXinVe,
    DateTime? thoiGianXuongTruong,
    DateTime? ngayXuongTruong,
    String? tenNguoiDon,
    String? cccdNguoiDon,
    String? sdtNguoiDon,
    List<DateTime>? danhSachNgayCatCom,
    String? idNguoiDuyet,
    String? tenNguoiDuyet,
    DateTime? thoiGianDuyet,
    TrangThaiVePhep? trangThai,
    NguonVePhep? nguon,
    String? lyDoTuChoi,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return XinVePhep(
      id: id ?? this.id,
      idHocSinh: idHocSinh ?? this.idHocSinh,
      hoTenHocSinh: hoTenHocSinh ?? this.hoTenHocSinh,
      soTheHocSinh: soTheHocSinh ?? this.soTheHocSinh,
      idLop: idLop ?? this.idLop,
      tenLop: tenLop ?? this.tenLop,
      idPhuHuynh: idPhuHuynh ?? this.idPhuHuynh,
      tenPhuHuynh: tenPhuHuynh ?? this.tenPhuHuynh,
      lyDo: lyDo ?? this.lyDo,
      thoiGianXinVe: thoiGianXinVe ?? this.thoiGianXinVe,
      ngayXinVe: ngayXinVe ?? this.ngayXinVe,
      thoiGianXuongTruong: thoiGianXuongTruong ?? this.thoiGianXuongTruong,
      ngayXuongTruong: ngayXuongTruong ?? this.ngayXuongTruong,
      tenNguoiDon: tenNguoiDon ?? this.tenNguoiDon,
      cccdNguoiDon: cccdNguoiDon ?? this.cccdNguoiDon,
      sdtNguoiDon: sdtNguoiDon ?? this.sdtNguoiDon,
      danhSachNgayCatCom: danhSachNgayCatCom ?? this.danhSachNgayCatCom,
      idNguoiDuyet: idNguoiDuyet ?? this.idNguoiDuyet,
      tenNguoiDuyet: tenNguoiDuyet ?? this.tenNguoiDuyet,
      thoiGianDuyet: thoiGianDuyet ?? this.thoiGianDuyet,
      trangThai: trangThai ?? this.trangThai,
      nguon: nguon ?? this.nguon,
      lyDoTuChoi: lyDoTuChoi ?? this.lyDoTuChoi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
