import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/xin_ra_vao.dart';
import '../../../services/xin_ra_vao_service.dart';

class HocSinhRaNgoaiScreen extends StatefulWidget {
  final String idHocSinh;
  final String tenHocSinh;

  const HocSinhRaNgoaiScreen({
    super.key,
    required this.idHocSinh,
    required this.tenHocSinh,
  });

  @override
  State<HocSinhRaNgoaiScreen> createState() => _HocSinhRaNgoaiScreenState();
}

class _HocSinhRaNgoaiScreenState extends State<HocSinhRaNgoaiScreen> {
  List<XinRaVao> _xinRaVaoList = [];
  bool _isLoading = true;
  TrangThaiXin? _selectedTrangThai;
  LoaiXin? _selectedLoai;

  @override
  void initState() {
    super.initState();
    _loadXinRaVaoList();
  }

  Future<void> _loadXinRaVaoList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await XinRaVaoService.filterXinRaVaoByIdHs(
        idHs: widget.idHocSinh,
        trangThai: _selectedTrangThai,
        loai: _selectedLoai,
      );

      setState(() {
        _xinRaVaoList = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Lỗi khi tải dữ liệu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
    }
  }

  Widget _buildFilterDropdowns() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<TrangThaiXin>(
              value: _selectedTrangThai,
              hint: const Text('Trạng thái'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<TrangThaiXin>(
                  value: null,
                  child: Text('Tất cả trạng thái'),
                ),
                ...TrangThaiXin.values.map((trangThai) {
                  return DropdownMenuItem(
                    value: trangThai,
                    child: Text(_getTrangThaiText(trangThai)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTrangThai = value;
                });
                _loadXinRaVaoList();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<LoaiXin>(
              value: _selectedLoai,
              hint: const Text('Loại xin'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<LoaiXin>(
                  value: null,
                  child: Text('Tất cả loại'),
                ),
                ...LoaiXin.values.map((loai) {
                  return DropdownMenuItem(
                    value: loai,
                    child: Text(_getLoaiText(loai)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLoai = value;
                });
                _loadXinRaVaoList();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXinRaVaoCard(XinRaVao xinRaVao) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getLoaiText(xinRaVao.loai),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTrangThaiColor(xinRaVao.trangThai),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTrangThaiText(xinRaVao.trangThai),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lý do: ${xinRaVao.lyDo}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Thời gian xin: ${DateFormat('dd/MM/yyyy HH:mm').format(xinRaVao.thoiGianXin)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (xinRaVao.thoiGianVaoDuKien != null)
              Text(
                'Dự kiến vào lại: ${DateFormat('dd/MM/yyyy HH:mm').format(xinRaVao.thoiGianVaoDuKien!)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            if (xinRaVao.thoiGianVaoThucTe != null)
              Text(
                'Thời gian vào thực tế: ${DateFormat('dd/MM/yyyy HH:mm').format(xinRaVao.thoiGianVaoThucTe!)}',
                style: const TextStyle(fontSize: 14, color: Colors.green),
              ),
            if (xinRaVao.lyDoTuChoi != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Lý do từ chối: ${xinRaVao.lyDoTuChoi}',
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTrangThaiText(TrangThaiXin trangThai) {
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
        return 'Xin ra ngoài';
      case LoaiXin.vaoLai:
        return 'Vào lại';
      case LoaiXin.tamNghi:
        return 'Tạm nghỉ';
    }
  }

  Color _getTrangThaiColor(TrangThaiXin trangThai) {
    switch (trangThai) {
      case TrangThaiXin.choDuyet:
        return Colors.orange;
      case TrangThaiXin.daDuyet:
        return Colors.green;
      case TrangThaiXin.daVao:
        return Colors.blue;
      case TrangThaiXin.tuChoi:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách xin ra ngoài - ${widget.tenHocSinh}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterDropdowns(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _xinRaVaoList.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có dữ liệu',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadXinRaVaoList,
                        child: ListView.builder(
                          itemCount: _xinRaVaoList.length,
                          itemBuilder: (context, index) {
                            return _buildXinRaVaoCard(_xinRaVaoList[index]);
                          },
                        ),
                      ),
          ),
        ],
      )
    );
  }
}