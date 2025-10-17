import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quan_ly_hoc_sinh/screens/hoc_sinh/xac_thuc_khuon_mat/xac_thuc_khuon_mat_screen.dart';
import 'package:quan_ly_hoc_sinh/services/local_data_service.dart';
import '../../../models/xin_ra_vao.dart';
import '../../../services/xin_ra_vao_service.dart';

class LichSuRaVaoScreen extends StatefulWidget {
  const LichSuRaVaoScreen({Key? key}) : super(key: key);

  @override
  State<LichSuRaVaoScreen> createState() => _LichSuRaVaoScreenState();
}

class _LichSuRaVaoScreenState extends State<LichSuRaVaoScreen> {
  late Future<List<XinRaVao>> _futureLichSuRaVao;
  String? _selectedFilter = 'all';
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final LocalDataService localDataService = LocalDataService.instance;

  @override
  void initState() {
    super.initState();
    _loadLichSuRaVao();
  }

  void _loadLichSuRaVao() {
    final idHs = localDataService.getId();
    if (idHs == null) {
      _futureLichSuRaVao = Future.value([]);
    } else {
      // Apply filter if selected
      TrangThaiXin? trangThai;
      if (_selectedFilter == 'cho_duyet') {
        trangThai = TrangThaiXin.choDuyet;
      } else if (_selectedFilter == 'da_duyet') {
        trangThai = TrangThaiXin.daDuyet;
      } else if (_selectedFilter == 'da_vao') {
        trangThai = TrangThaiXin.daVao;
      } else if (_selectedFilter == 'tu_choi') {
        trangThai = TrangThaiXin.tuChoi;
      }
      try {
        _futureLichSuRaVao = XinRaVaoService.filterXinRaVaoByIdHs(
          idHs: idHs,
          trangThai: trangThai,
        );
      } catch (e) {
        _futureLichSuRaVao = Future.error(
          'Lỗi khi tải dữ liệu: ${e.toString()}',
        );
        debugPrint('Lỗi khi tải dữ liệu: ${e.toString()}');
      }
    }
  }

  Future<void> _handleCheckIn(XinRaVao record) async {
    try {
      if (record.trangThai == TrangThaiXin.daDuyet) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                XacThucKhuonMatScreen(isUploadFace: false, idRaVao: record.id!),
          ),
        );
        setState(() {
          debugPrint("reload data");
          _loadLichSuRaVao();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ có thể check-in khi đã được duyệt'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi check-in: ${e.toString()}')),
      );
    }
  }

  Color _getStatusColor(TrangThaiXin trangThai) {
    switch (trangThai) {
      case TrangThaiXin.choDuyet:
        return Colors.orange;
      case TrangThaiXin.daDuyet:
        return Colors.blue;
      case TrangThaiXin.daVao:
        return Colors.green;
      case TrangThaiXin.tuChoi:
        return Colors.red;
    }
  }

  String _getStatusText(TrangThaiXin trangThai) {
    switch (trangThai) {
      case TrangThaiXin.choDuyet:
        return 'Chờ duyệt';
      case TrangThaiXin.daDuyet:
        return 'Đã duyệt';
      case TrangThaiXin.daVao:
        return 'Đã vào';
      case TrangThaiXin.tuChoi:
        return 'Từ chối';
    }
  }

  String _getLoaiText(LoaiXin loai) {
    switch (loai) {
      case LoaiXin.xinRa:
        return 'Xin ra';
      case LoaiXin.vaoLai:
        return 'Vào lại';
      case LoaiXin.tamNghi:
        return 'Tạm nghỉ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử ra vào'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
                _loadLichSuRaVao();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Tất cả')),
              const PopupMenuItem(value: 'cho_duyet', child: Text('Chờ duyệt')),
              const PopupMenuItem(value: 'da_duyet', child: Text('Đã duyệt')),
              const PopupMenuItem(value: 'da_vao', child: Text('Đã vào')),
              const PopupMenuItem(value: 'tu_choi', child: Text('Từ chối')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadLichSuRaVao();
          });
        },
        child: FutureBuilder<List<XinRaVao>>(
          future: _futureLichSuRaVao,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Không có lịch sử ra vào'));
            }

            final records = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final record = records[index];
                return Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(_getLoaiText(record.loai)),
                              backgroundColor: Colors.blue[100],
                            ),
                            Chip(
                              label: Text(_getStatusText(record.trangThai)),
                              backgroundColor: _getStatusColor(
                                record.trangThai,
                              ).withOpacity(0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Thời gian xin:',
                          _dateFormat.format(record.thoiGianXin),
                        ),
                        if (record.thoiGianVaoDuKien != null)
                          _buildInfoRow(
                            'Dự kiến vào:',
                            _dateFormat.format(record.thoiGianVaoDuKien!),
                          ),
                        if (record.thoiGianVaoThucTe != null)
                          _buildInfoRow(
                            'Thực tế vào:',
                            _dateFormat.format(record.thoiGianVaoThucTe!),
                          ),
                        _buildInfoRow('Lý do:', record.lyDo),
                        if (record.nguoiDuyet != null &&
                            record.nguoiDuyet!.isNotEmpty)
                          _buildInfoRow('Người duyệt:', record.nguoiDuyet!),
                        if (record.lyDoTuChoi != null &&
                            record.lyDoTuChoi!.isNotEmpty)
                          _buildInfoRow('Lý do từ chối:', record.lyDoTuChoi!),

                        const SizedBox(height: 8),
                        if (record.trangThai == TrangThaiXin.daDuyet)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _handleCheckIn(record),
                              icon: const Icon(Icons.login),
                              label: const Text('Check-in'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
