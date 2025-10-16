import 'package:cloud_firestore/cloud_firestore.dart';

class PhuHuynh {
  final String? id;
  final String hoTen;
  final String soCccd;
  final String soDienThoai;
  final String quanHe;
  final String idHs;
  final String gmail;
  final DateTime createdAt;

  PhuHuynh({
    this.id,
    required this.hoTen,
    required this.soCccd,
    required this.soDienThoai,
    required this.quanHe,
    required this.idHs,
    required this.gmail,
    required this.createdAt,
  });

  factory PhuHuynh.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PhuHuynh(
      id: doc.id,
      hoTen: data['ho_ten'] ?? '',
      soCccd: data['so_cccd'] ?? '',
      soDienThoai: data['so_dien_thoai'] ?? '',
      quanHe: data['quan_he'] ?? '',
      idHs: data['id_hs'] ?? '',
      gmail: data['gmail'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ho_ten': hoTen,
      'so_cccd': soCccd,
      'so_dien_thoai': soDienThoai,
      'quan_he': quanHe,
      'id_hs': idHs,
      'gmail': gmail,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  PhuHuynh copyWith({
    String? id,
    String? hoTen,
    String? soCccd,
    String? soDienThoai,
    String? quanHe,
    String? idHs,
    String? gmail,
    DateTime? createdAt,
  }) {
    return PhuHuynh(
      id: id ?? this.id,
      hoTen: hoTen ?? this.hoTen,
      soCccd: soCccd ?? this.soCccd,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      quanHe: quanHe ?? this.quanHe,
      idHs: idHs ?? this.idHs,
      gmail: gmail ?? this.gmail,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
