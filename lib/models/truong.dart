import 'package:cloud_firestore/cloud_firestore.dart';

class Truong {
  final String? id;
  final String tenTruong;
  final String diaChi;
  final String sdt;
  final String maTruong;
  final DateTime createdAt;
  final DateTime updatedAt;

  Truong({
    this.id,
    required this.tenTruong,
    required this.diaChi,
    required this.sdt,
    required this.maTruong,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Truong.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Truong(
      id: doc.id,
      tenTruong: data['ten_truong'] ?? '',
      diaChi: data['dia_chi'] ?? '',
      sdt: data['sdt'] ?? '',
      maTruong: data['ma_truong'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ten_truong': tenTruong,
      'dia_chi': diaChi,
      'sdt': sdt,
      'ma_truong': maTruong,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  Truong copyWith({
    String? id,
    String? tenTruong,
    String? diaChi,
    String? sdt,
    String? maTruong,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Truong(
      id: id ?? this.id,
      tenTruong: tenTruong ?? this.tenTruong,
      diaChi: diaChi ?? this.diaChi,
      sdt: sdt ?? this.sdt,
      maTruong: maTruong ?? this.maTruong,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
