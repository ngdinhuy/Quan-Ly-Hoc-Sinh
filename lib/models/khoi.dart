import 'package:cloud_firestore/cloud_firestore.dart';

class Khoi {
  final String? id;
  final String idTruong;
  final String tenKhoi;
  final String maKhoi;
  final String? ghiChu;
  final DateTime createdAt;

  Khoi({
    this.id,
    required this.idTruong,
    required this.tenKhoi,
    required this.maKhoi,
    this.ghiChu,
    required this.createdAt,
  });

  factory Khoi.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Khoi(
      id: doc.id,
      idTruong: data['id_truong'] ?? '',
      tenKhoi: data['ten_khoi'] ?? '',
      maKhoi: data['ma_khoi'] ?? '',
      ghiChu: data['ghi_chu'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_truong': idTruong,
      'ten_khoi': tenKhoi,
      'ma_khoi': maKhoi,
      'ghi_chu': ghiChu,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  Khoi copyWith({
    String? id,
    String? idTruong,
    String? tenKhoi,
    String? maKhoi,
    String? ghiChu,
    DateTime? createdAt,
  }) {
    return Khoi(
      id: id ?? this.id,
      idTruong: idTruong ?? this.idTruong,
      tenKhoi: tenKhoi ?? this.tenKhoi,
      maKhoi: maKhoi ?? this.maKhoi,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
