import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class for time period (start/end)
class ThoiGianCa {
  final String batDau; // "HH:mm" format
  final String ketThuc; // "HH:mm" format

  ThoiGianCa({required this.batDau, required this.ketThuc});

  factory ThoiGianCa.fromMap(Map<String, dynamic> map) {
    return ThoiGianCa(
      batDau: map['bat_dau'] ?? '07:00',
      ketThuc: map['ket_thuc'] ?? '07:30',
    );
  }

  Map<String, dynamic> toMap() {
    return {'bat_dau': batDau, 'ket_thuc': ketThuc};
  }

  ThoiGianCa copyWith({String? batDau, String? ketThuc}) {
    return ThoiGianCa(
      batDau: batDau ?? this.batDau,
      ketThuc: ketThuc ?? this.ketThuc,
    );
  }
}

/// Attendance config for a single day (3 periods)
class CaHocConfig {
  final ThoiGianCa caSang;
  final ThoiGianCa caTrua;
  final ThoiGianCa caChieuToi;

  CaHocConfig({
    required this.caSang,
    required this.caTrua,
    required this.caChieuToi,
  });

  factory CaHocConfig.fromMap(Map<String, dynamic> map) {
    return CaHocConfig(
      caSang: ThoiGianCa.fromMap(map['ca_sang'] ?? {}),
      caTrua: ThoiGianCa.fromMap(map['ca_trua'] ?? {}),
      caChieuToi: ThoiGianCa.fromMap(map['ca_chieu_toi'] ?? {}),
    );
  }

  factory CaHocConfig.defaultConfig() {
    return CaHocConfig(
      caSang: ThoiGianCa(batDau: '07:00', ketThuc: '11:30'),
      caTrua: ThoiGianCa(batDau: '13:00', ketThuc: '14:30'),
      caChieuToi: ThoiGianCa(batDau: '19:00', ketThuc: '21:30'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ca_sang': caSang.toMap(),
      'ca_trua': caTrua.toMap(),
      'ca_chieu_toi': caChieuToi.toMap(),
    };
  }

  CaHocConfig copyWith({
    ThoiGianCa? caSang,
    ThoiGianCa? caTrua,
    ThoiGianCa? caChieuToi,
  }) {
    return CaHocConfig(
      caSang: caSang ?? this.caSang,
      caTrua: caTrua ?? this.caTrua,
      caChieuToi: caChieuToi ?? this.caChieuToi,
    );
  }
}

class Lop {
  final String? id;
  final String idTruong;
  final String idKhoi;
  final String tenLop;
  final int siSo;
  final String maLop;
  final String phongSo;
  final DateTime createdAt;
  final Map<String, CaHocConfig>? cauHinhDiemDanh; // key = "1"-"7" (Mon-Sun)

  Lop({
    this.id,
    required this.idTruong,
    required this.idKhoi,
    required this.tenLop,
    required this.siSo,
    required this.maLop,
    required this.phongSo,
    required this.createdAt,
    this.cauHinhDiemDanh,
  });

  factory Lop.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse attendance config if exists
    Map<String, CaHocConfig>? cauHinhDiemDanh;
    if (data['cau_hinh_diem_danh'] != null) {
      final configData = data['cau_hinh_diem_danh'] as Map<String, dynamic>;
      cauHinhDiemDanh = configData.map(
        (key, value) => MapEntry(key, CaHocConfig.fromMap(value)),
      );
    }

    return Lop(
      id: doc.id,
      idTruong: data['id_truong'] ?? '',
      idKhoi: data['id_khoi'] ?? '',
      tenLop: data['ten_lop'] ?? '',
      siSo: data['si_so'] ?? 0,
      maLop: data['ma_lop'] ?? '',
      phongSo: data['phong_so'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      cauHinhDiemDanh: cauHinhDiemDanh,
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = {
      'id_truong': idTruong,
      'id_khoi': idKhoi,
      'ten_lop': tenLop,
      'si_so': siSo,
      'ma_lop': maLop,
      'phong_so': phongSo,
      'created_at': Timestamp.fromDate(createdAt),
    };

    if (cauHinhDiemDanh != null) {
      data['cau_hinh_diem_danh'] = cauHinhDiemDanh!.map(
        (key, value) => MapEntry(key, value.toMap()),
      );
    }

    return data;
  }

  Lop copyWith({
    String? id,
    String? idTruong,
    String? idKhoi,
    String? tenLop,
    int? siSo,
    String? maLop,
    String? phongSo,
    DateTime? createdAt,
    Map<String, CaHocConfig>? cauHinhDiemDanh,
  }) {
    return Lop(
      id: id ?? this.id,
      idTruong: idTruong ?? this.idTruong,
      idKhoi: idKhoi ?? this.idKhoi,
      tenLop: tenLop ?? this.tenLop,
      siSo: siSo ?? this.siSo,
      maLop: maLop ?? this.maLop,
      phongSo: phongSo ?? this.phongSo,
      createdAt: createdAt ?? this.createdAt,
      cauHinhDiemDanh: cauHinhDiemDanh ?? this.cauHinhDiemDanh,
    );
  }

  /// Get attendance config for a specific day of week
  /// dayOfWeek: 1=Monday, 7=Sunday (ISO 8601)
  CaHocConfig? getConfigForDay(int dayOfWeek) {
    if (cauHinhDiemDanh == null) return null;
    return cauHinhDiemDanh![dayOfWeek.toString()];
  }

  /// Get attendance config for today
  CaHocConfig? getConfigForToday() {
    final now = DateTime.now();
    // DateTime.weekday: 1=Monday, 7=Sunday (ISO 8601)
    return getConfigForDay(now.weekday);
  }
}
