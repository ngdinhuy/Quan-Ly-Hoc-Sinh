import 'package:cloud_firestore/cloud_firestore.dart';

class PhanCongTrucBan {
  final String? id;
  final String idTruong;
  final String idGiaoVien;
  final List<DateTime> ngayTrucBan;
  final String? ghiChu;
  final DateTime createdAt;

  PhanCongTrucBan({
    this.id,
    required this.idTruong,
    required this.idGiaoVien,
    required this.ngayTrucBan,
    this.ghiChu,
    required this.createdAt,
  });

  factory PhanCongTrucBan.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convert list of Timestamps to list of DateTime objects
    List<DateTime> ngayTruc = [];
    if (data['ngay_truc_ban'] != null) {
      final List<dynamic> ngayTrucData = data['ngay_truc_ban'];
      ngayTruc = ngayTrucData.map((timestamp) =>
        (timestamp as Timestamp).toDate()).toList();
    }

    return PhanCongTrucBan(
      id: doc.id,
      idTruong: data['id_truong'] ?? '',
      idGiaoVien: data['id_giao_vien'] ?? '',
      ngayTrucBan: ngayTruc,
      ghiChu: data['ghi_chu'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    // Convert list of DateTime objects to list of Timestamps
    List<Timestamp> ngayTrucTimestamps =
      ngayTrucBan.map((date) => Timestamp.fromDate(date)).toList();

    return {
      'id_truong': idTruong,
      'id_giao_vien': idGiaoVien,
      'ngay_truc_ban': ngayTrucTimestamps,
      'ghi_chu': ghiChu,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  PhanCongTrucBan copyWith({
    String? id,
    String? idTruong,
    String? idGiaoVien,
    List<DateTime>? ngayTrucBan,
    String? ghiChu,
    DateTime? createdAt,
  }) {
    return PhanCongTrucBan(
      id: id ?? this.id,
      idTruong: idTruong ?? this.idTruong,
      idGiaoVien: idGiaoVien ?? this.idGiaoVien,
      ngayTrucBan: ngayTrucBan ?? this.ngayTrucBan,
      ghiChu: ghiChu ?? this.ghiChu,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}