import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/phu_huynh.dart';
import '../../../models/xin_ve_phep.dart';
import '../../../services/local_data_service.dart';
import '../../../services/phu_huynh_service.dart';
import '../../../services/xin_ve_phep_service.dart';
import '../../../widgets/xin_ve_phep_detail_dialog.dart';

class LichSuVePhepPhuHuynhScreen extends StatefulWidget {
  const LichSuVePhepPhuHuynhScreen({super.key});

  @override
  State<LichSuVePhepPhuHuynhScreen> createState() =>
      _LichSuVePhepPhuHuynhScreenState();
}

class _LichSuVePhepPhuHuynhScreenState
    extends State<LichSuVePhepPhuHuynhScreen> {
  final LocalDataService _localDataService = LocalDataService.instance;
  TrangThaiVePhep? _filterStatus;
  PhuHuynh? _phuHuynh;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParentData();
  }

  Future<void> _loadParentData() async {
    try {
      final parentId = _localDataService.getId();
      if (parentId == null) return;

      final phuHuynh = await PhuHuynhService.getPhuHuynhById(parentId);

      if (mounted) {
        setState(() {
          _phuHuynh = phuHuynh;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lịch Sử Về Phép Của Con'),
          backgroundColor: Colors.orange,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_phuHuynh == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lịch Sử Về Phép Của Con'),
          backgroundColor: Colors.orange,
        ),
        body: const Center(child: Text('Không tìm thấy thông tin phụ huynh')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Về Phép Của Con'),
        backgroundColor: Colors.orange,
        actions: [
          PopupMenuButton<TrangThaiVePhep?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              setState(() {
                _filterStatus = status;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Tất cả')),
              const PopupMenuItem(
                value: TrangThaiVePhep.choDuyet,
                child: Text('Chờ duyệt'),
              ),
              const PopupMenuItem(
                value: TrangThaiVePhep.daDuyet,
                child: Text('Đã duyệt'),
              ),
              const PopupMenuItem(
                value: TrangThaiVePhep.tuChoi,
                child: Text('Từ chối'),
              ),
              const PopupMenuItem(
                value: TrangThaiVePhep.daVeTruong,
                child: Text('Đã về trường'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<XinVePhep>>(
        stream: XinVePhepService.streamXinVePhepByHocSinh(_phuHuynh!.idHs),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có yêu cầu về phép nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          var requests = snapshot.data!;

          // Apply filter
          if (_filterStatus != null) {
            requests = requests
                .where((request) => request.trangThai == _filterStatus)
                .toList();
          }

          if (requests.isEmpty) {
            return const Center(child: Text('Không có yêu cầu nào'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Reload to refresh stream
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return _buildRequestCard(request);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(XinVePhep request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => XinVePhepDetailDialog(xinVePhep: request),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request.lyDo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(request.trangThai),
                ],
              ),
              const SizedBox(height: 8),
              _buildSourceBadge(request),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.calendar_today,
                'Ngày về:',
                DateFormat('dd/MM/yyyy').format(request.ngayXinVe),
              ),
              if (request.ngayXuongTruong != null)
                _buildInfoRow(
                  Icons.event_available,
                  'Ngày về trường:',
                  DateFormat('dd/MM/yyyy').format(request.ngayXuongTruong!),
                ),
              _buildInfoRow(Icons.person, 'Người đón:', request.tenNguoiDon),
              if (request.danhSachNgayCatCom.isNotEmpty)
                _buildInfoRow(
                  Icons.restaurant,
                  'Cắt cơm:',
                  '${request.danhSachNgayCatCom.length} ngày',
                ),
              if (request.trangThai == TrangThaiVePhep.daDuyet &&
                  request.tenNguoiDuyet != null)
                _buildInfoRow(
                  Icons.check_circle,
                  'Người duyệt:',
                  request.tenNguoiDuyet!,
                ),
              if (request.trangThai == TrangThaiVePhep.tuChoi &&
                  request.lyDoTuChoi != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lý do từ chối: ${request.lyDoTuChoi}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Tạo lúc: ${DateFormat('HH:mm dd/MM/yyyy').format(request.createdAt)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceBadge(XinVePhep request) {
    String sourceText;
    Color color;

    switch (request.nguon) {
      case NguonVePhep.appPhuHuynh:
        sourceText = 'Phụ huynh nộp';
        color = Colors.purple;
        break;
      case NguonVePhep.appHocSinh:
        sourceText = 'Học sinh nộp';
        color = Colors.blue;
        break;
      case NguonVePhep.giaoVienNhap:
        sourceText = 'Giáo viên nhập';
        color = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.source, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            sourceText,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TrangThaiVePhep status) {
    Color color;
    String text;

    switch (status) {
      case TrangThaiVePhep.choDuyet:
        color = Colors.orange;
        text = 'Chờ duyệt';
        break;
      case TrangThaiVePhep.daDuyet:
        color = Colors.green;
        text = 'Đã duyệt';
        break;
      case TrangThaiVePhep.tuChoi:
        color = Colors.red;
        text = 'Từ chối';
        break;
      case TrangThaiVePhep.daVeTruong:
        color = Colors.blue;
        text = 'Đã về trường';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
