import 'package:cloud_firestore/cloud_firestore.dart';

enum NguonXin { appPh, appHs, gvNhap }

enum LoaiXin { xinRa, vaoLai, tamNghi }

enum TrangThaiXin { choDuyet, daDuyet, daVao, tuChoi }

class XinRaVao {
  final String? id;
  final String idHs;
  final String hoTenHs;
  final String soTheHocSinh;
  final String idLop;
  final String lyDo;
  final NguonXin nguon;
  final LoaiXin loai;
  final DateTime thoiGianXin;
  final DateTime? thoiGianVaoDuKien;
  final DateTime? thoiGianVaoThucTe;
  final TrangThaiXin trangThai;
  final String? nguoiDuyet;
  final String? lyDoTuChoi;
  final DateTime createdAt;

  XinRaVao({
    this.id,
    required this.idHs,
    required this.hoTenHs,
    required this.soTheHocSinh,
    required this.idLop,
    required this.lyDo,
    required this.nguon,
    required this.loai,
    required this.thoiGianXin,
    this.thoiGianVaoDuKien,
    this.thoiGianVaoThucTe,
    this.trangThai = TrangThaiXin.choDuyet,
    this.nguoiDuyet,
    this.lyDoTuChoi,
    required this.createdAt,
  });

  factory XinRaVao.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return XinRaVao(
      id: doc.id,
      idHs: data['id_hs'] ?? '',
      hoTenHs: data['ho_ten_hs'] ?? '',
      soTheHocSinh: data['so_the_hoc_sinh'] ?? '',
      idLop: data['id_lop'] ?? '',
      lyDo: data['ly_do'] ?? '',
      nguon: _parseNguon(data['nguon']),
      loai: _parseLoai(data['loai']),
      thoiGianXin: (data['thoi_gian_xin'] as Timestamp).toDate(),
      thoiGianVaoDuKien:
          data['thoi_gian_vao_du_kien'] != null
              ? (data['thoi_gian_vao_du_kien'] as Timestamp).toDate()
              : null,
      thoiGianVaoThucTe:
          data['thoi_gian_vao_thuc_te'] != null
              ? (data['thoi_gian_vao_thuc_te'] as Timestamp).toDate()
              : null,
      trangThai: _parseTrangThai(data['trang_thai']),
      nguoiDuyet: data['nguoi_duyet'],
      lyDoTuChoi: data['ly_do_tu_choi'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  static NguonXin _parseNguon(String? nguon) {
    switch (nguon) {
      case 'app_ph':
        return NguonXin.appPh;
      case 'app_hs':
        return NguonXin.appHs;
      case 'gv_nhap':
        return NguonXin.gvNhap;
      default:
        return NguonXin.gvNhap;
    }
  }

  static LoaiXin _parseLoai(String? loai) {
    switch (loai) {
      case 'vao_lai':
        return LoaiXin.vaoLai;
      case 'tam_nghi':
        return LoaiXin.tamNghi;
      default:
        return LoaiXin.xinRa;
    }
  }

  static TrangThaiXin _parseTrangThai(String? status) {
    switch (status) {
      case 'da_duyet':
        return TrangThaiXin.daDuyet;
      case 'da_vao':
        return TrangThaiXin.daVao;
      case 'tu_choi':
        return TrangThaiXin.tuChoi;
      default:
        return TrangThaiXin.choDuyet;
    }
  }

  String get nguonString {
    switch (nguon) {
      case NguonXin.appPh:
        return 'app_ph';
      case NguonXin.appHs:
        return 'app_hs';
      case NguonXin.gvNhap:
        return 'gv_nhap';
    }
  }

  String get loaiString {
    switch (loai) {
      case LoaiXin.xinRa:
        return 'xin_ra';
      case LoaiXin.vaoLai:
        return 'vao_lai';
      case LoaiXin.tamNghi:
        return 'tam_nghi';
    }
  }

  String get trangThaiString {
    switch (trangThai) {
      case TrangThaiXin.choDuyet:
        return 'cho_duyet';
      case TrangThaiXin.daDuyet:
        return 'da_duyet';
      case TrangThaiXin.daVao:
        return 'da_vao';
      case TrangThaiXin.tuChoi:
        return 'tu_choi';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_hs': idHs,
      'ho_ten_hs': hoTenHs,
      'so_the_hoc_sinh': soTheHocSinh,
      'id_lop': idLop,
      'ly_do': lyDo,
      'nguon': nguonString,
      'loai': loaiString,
      'thoi_gian_xin': Timestamp.fromDate(thoiGianXin),
      'thoi_gian_vao_du_kien':
          thoiGianVaoDuKien != null
              ? Timestamp.fromDate(thoiGianVaoDuKien!)
              : null,
      'thoi_gian_vao_thuc_te':
          thoiGianVaoThucTe != null
              ? Timestamp.fromDate(thoiGianVaoThucTe!)
              : null,
      'trang_thai': trangThaiString,
      'nguoi_duyet': nguoiDuyet,
      'ly_do_tu_choi': lyDoTuChoi,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  XinRaVao copyWith({
    String? id,
    String? idHs,
    String? hoTenHs,
    String? soTheHocSinh,
    String? idLop,
    String? lyDo,
    NguonXin? nguon,
    LoaiXin? loai,
    DateTime? thoiGianXin,
    DateTime? thoiGianVaoDuKien,
    DateTime? thoiGianVaoThucTe,
    TrangThaiXin? trangThai,
    String? nguoiDuyet,
    String? lyDoTuChoi,
    DateTime? createdAt,
  }) {
    return XinRaVao(
      id: id ?? this.id,
      idHs: idHs ?? this.idHs,
      hoTenHs: hoTenHs ?? this.hoTenHs,
      soTheHocSinh: soTheHocSinh ?? this.soTheHocSinh,
      idLop: idLop ?? this.idLop,
      lyDo: lyDo ?? this.lyDo,
      nguon: nguon ?? this.nguon,
      loai: loai ?? this.loai,
      thoiGianXin: thoiGianXin ?? this.thoiGianXin,
      thoiGianVaoDuKien: thoiGianVaoDuKien ?? this.thoiGianVaoDuKien,
      thoiGianVaoThucTe: thoiGianVaoThucTe ?? this.thoiGianVaoThucTe,
      trangThai: trangThai ?? this.trangThai,
      nguoiDuyet: nguoiDuyet ?? this.nguoiDuyet,
      lyDoTuChoi: lyDoTuChoi ?? this.lyDoTuChoi,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
