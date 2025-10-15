import 'package:cloud_firestore/cloud_firestore.dart';

class PhanCongChuNhiem {
  final String? id;
  final String idGv;
  final String idLop;
  final DateTime tuNgay;
  final DateTime? denNgay;
  final String? ghiChu;
  final DateTime createdAt;

  PhanCongChuNhiem({
    this.id,
    required this.idGv,
    required this.idLop,
    required this.tuNgay,
    this.denNgay,
    this.ghiChu,
    required this.createdAt,
  });

  factory PhanCongChuNhiem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PhanCongChuNhiem(
      id: doc.id,
      idGv: data['id_gv'] ?? '',
      idLop: data['id_lop'] ?? '',
      tuNgay: (data['tu_ngay'] as Timestamp).toDate(),
      denNgay:
          data['den_ngay'] != null
              ? (data['den_ngay'] as Timestamp).toDate()
              : null,
      ghiChu: data['ghi_chu'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_gv': idGv,
      'id_lop': idLop,
      'tu_ngay': Timestamp.fromDate(tuNgay),
      'den_ngay': denNgay != null ? Timestamp.fromDate(denNgay!) : null,
      'ghi_chu': ghiChu,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  PhanCongChuNhiem copyWith({
    String? id,
    String? idGv,
    String? idLop,
    DateTime? tuNgay,
    DateTime? denNgay,
    String? ghiChu,
    DateTime? createdAt,
  }) {
    return PhanCongChuNhiem(
      id: id ?? this.id,
      idGv: idGv ?? this.idGv,
      idLop: idLop ?? this.idLop,
      tuNgay: tuNgay ?? this.tuNgay,
      denNgay: denNgay ?? this.denNgay,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
