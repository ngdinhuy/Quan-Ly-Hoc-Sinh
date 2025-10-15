import 'package:cloud_firestore/cloud_firestore.dart';

enum CaTruc { caSang, caChieu, caToanNgay }

class PhanCongTruc {
  final String? id;
  final String idTruong;
  final String ngay;
  final String idGv;
  final CaTruc ca;
  final String? ghiChu;
  final DateTime createdAt;

  PhanCongTruc({
    this.id,
    required this.idTruong,
    required this.ngay,
    required this.idGv,
    required this.ca,
    this.ghiChu,
    required this.createdAt,
  });

  factory PhanCongTruc.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PhanCongTruc(
      id: doc.id,
      idTruong: data['id_truong'] ?? '',
      ngay: data['ngay'] ?? '',
      idGv: data['id_gv'] ?? '',
      ca: _parseCa(data['ca']),
      ghiChu: data['ghi_chu'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  static CaTruc _parseCa(String? ca) {
    switch (ca) {
      case 'ca_chieu':
        return CaTruc.caChieu;
      case 'ca_toan_ngay':
        return CaTruc.caToanNgay;
      default:
        return CaTruc.caSang;
    }
  }

  String get caString {
    switch (ca) {
      case CaTruc.caSang:
        return 'ca_sang';
      case CaTruc.caChieu:
        return 'ca_chieu';
      case CaTruc.caToanNgay:
        return 'ca_toan_ngay';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_truong': idTruong,
      'ngay': ngay,
      'id_gv': idGv,
      'ca': caString,
      'ghi_chu': ghiChu,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  PhanCongTruc copyWith({
    String? id,
    String? idTruong,
    String? ngay,
    String? idGv,
    CaTruc? ca,
    String? ghiChu,
    DateTime? createdAt,
  }) {
    return PhanCongTruc(
      id: id ?? this.id,
      idTruong: idTruong ?? this.idTruong,
      ngay: ngay ?? this.ngay,
      idGv: idGv ?? this.idGv,
      ca: ca ?? this.ca,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
