import 'package:cloud_firestore/cloud_firestore.dart';

class Lop {
  final String? id;
  final String idTruong;
  final String idKhoi;
  final String tenLop;
  final int siSo;
  final String maLop;
  final String phongSo;
  final DateTime createdAt;

  Lop({
    this.id,
    required this.idTruong,
    required this.idKhoi,
    required this.tenLop,
    required this.siSo,
    required this.maLop,
    required this.phongSo,
    required this.createdAt,
  });

  factory Lop.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Lop(
      id: doc.id,
      idTruong: data['id_truong'] ?? '',
      idKhoi: data['id_khoi'] ?? '',
      tenLop: data['ten_lop'] ?? '',
      siSo: data['si_so'] ?? 0,
      maLop: data['ma_lop'] ?? '',
      phongSo: data['phong_so'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_truong': idTruong,
      'id_khoi': idKhoi,
      'ten_lop': tenLop,
      'si_so': siSo,
      'ma_lop': maLop,
      'phong_so': phongSo,
      'created_at': Timestamp.fromDate(createdAt),
    };
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
    );
  }
}
