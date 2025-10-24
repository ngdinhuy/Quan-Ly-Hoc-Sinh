import 'package:flutter/material.dart';
import 'package:quan_ly_hoc_sinh/models/lop.dart';
import 'package:quan_ly_hoc_sinh/services/lop_service.dart';
import '../models/xin_ra_vao.dart';
import '../models/tham_ph.dart';
import '../services/xin_ra_vao_service.dart';
import '../services/tham_ph_service.dart';

class BaoCaoScreen extends StatefulWidget {
  const BaoCaoScreen({super.key});

  @override
  State<BaoCaoScreen> createState() => _BaoCaoScreenState();
}

class _BaoCaoScreenState extends State<BaoCaoScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<XinRaVao> _xinRaVaoList = [];
  List<ThamPh> _thamPhList = [];
  List<Lop> _lopList = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadLopList();
      await _loadReports();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReports() async {
    try {
      final xinRaVaoList = await XinRaVaoService.getXinRaVaoByDateRange(
        _startDate,
        _endDate,
      );
      final thamPhList = await ThamPhService.getThamPhByDateRange(
        _startDate,
        _endDate,
      );

      setState(() {
        _xinRaVaoList = xinRaVaoList;
        _thamPhList = thamPhList;
      });
    } catch (e) {
      debugPrint("huynd $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải báo cáo: $e')));
    }
  }

  Future<void> _loadLopList() async {
    _lopList = await LopService.getAllLop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Báo Cáo Thống Kê',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Từ ngày:'),
              const SizedBox(width: 8),
              InkWell(
                onTap: _selectStartDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_formatDate(_startDate)),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Đến ngày:'),
              const SizedBox(width: 8),
              InkWell(
                onTap: _selectEndDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_formatDate(_endDate)),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _loadReports,
                child: const Text('Tải Báo Cáo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'HS Ra Vào', icon: Icon(Icons.login)),
                    Tab(text: 'PH Thăm Con', icon: Icon(Icons.people)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildXinRaVaoReport(), _buildThamPhReport()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXinRaVaoReport() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _calculateXinRaVaoStats();

    return Column(
      children: [
        // Thống kê tổng quan (Giữ nguyên)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Tổng Yêu Cầu',
                  stats['total'].toString(),
                  Colors.blue,
                ),
                _buildStatCard(
                  'Chờ Duyệt',
                  stats['choDuyet'].toString(),
                  Colors.orange,
                ),
                _buildStatCard(
                  'Đã Duyệt',
                  stats['daDuyET'].toString(), // Sửa lỗi chính tả từ code gốc
                  Colors.green,
                ),
                _buildStatCard(
                  'Từ Chối',
                  stats['tuChoi'].toString(),
                  Colors.red,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Bảng chi tiết (Đây là phần thay đổi)
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias, // Thêm cái này để bo góc đẹp hơn
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Học Sinh')),
                    DataColumn(label: Text('Lớp')),
                    DataColumn(label: Text('Lý Do')),
                    DataColumn(label: Text('Thời Gian Xin')),
                    DataColumn(label: Text('Trạng Thái')),
                    DataColumn(label: Text('Nguồn')),
                  ],
                  rows: _xinRaVaoList.map((xin) {
                    return DataRow(
                      cells: [
                        DataCell(Text(xin.hoTenHs)),
                        DataCell(Text(_getLopTenById(xin.idLop))),
                        DataCell(Text(xin.lyDo)),
                        DataCell(Text(_formatDateTime(xin.thoiGianXin))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(xin.trangThai),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(xin.trangThai),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(_getNguonText(xin.nguon))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThamPhReport() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _calculateThamPhStats();

    return Column(
      children: [
        // Thống kê tổng quan (Giữ nguyên)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Tổng Lần Thăm',
                  stats['total'].toString(),
                  Colors.blue,
                ),
                _buildStatCard(
                  'Đang Thăm',
                  stats['dangTham'].toString(),
                  Colors.orange,
                ),
                _buildStatCard('Đã Về', stats['daVe'].toString(), Colors.green),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Bảng chi tiết (Đây là phần thay đổi)
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Phụ Huynh')),
                    DataColumn(label: Text('Học Sinh')),
                    DataColumn(label: Text('Phòng Số')),
                    DataColumn(label: Text('Thời Gian Đến')),
                    DataColumn(label: Text('Thời Gian Kết Thúc')),
                    DataColumn(label: Text('Trạng Thái')),
                  ],
                  rows: _thamPhList.map((thamPh) {
                    return DataRow(
                      cells: [
                        DataCell(Text(thamPh.hoTenPh)),
                        DataCell(Text(thamPh.hoTenHs)),
                        DataCell(Text(thamPh.phongSo)),
                        DataCell(Text(_formatDateTime(thamPh.thoiGianDen))),
                        DataCell(
                          Text(
                            thamPh.thoiGianKetThuc != null
                                ? _formatDateTime(thamPh.thoiGianKetThuc!)
                                : 'Chưa kết thúc',
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  thamPh.trangThai == TrangThaiTham.dangTham
                                      ? Colors.green
                                      : Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              thamPh.trangThai == TrangThaiTham.dangTham
                                  ? 'Đang thăm'
                                  : 'Đã về',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Map<String, int> _calculateXinRaVaoStats() {
    int total = _xinRaVaoList.length;
    int choDuyet =
        _xinRaVaoList.where((x) => x.trangThai == TrangThaiXin.choDuyet).length;
    int daDuyet =
        _xinRaVaoList.where((x) => x.trangThai == TrangThaiXin.daDuyet).length;
    int tuChoi =
        _xinRaVaoList.where((x) => x.trangThai == TrangThaiXin.tuChoi).length;

    return {
      'total': total,
      'choDuyet': choDuyet,
      'daDuyet': daDuyet,
      'tuChoi': tuChoi,
    };
  }

  Map<String, int> _calculateThamPhStats() {
    int total = _thamPhList.length;
    int dangTham =
        _thamPhList.where((t) => t.trangThai == TrangThaiTham.dangTham).length;
    int daVe =
        _thamPhList.where((t) => t.trangThai == TrangThaiTham.daVe).length;

    return {'total': total, 'dangTham': dangTham, 'daVe': daVe};
  }

  Color _getStatusColor(TrangThaiXin trangThai) {
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

  String _getNguonText(NguonXin nguon) {
    switch (nguon) {
      case NguonXin.appPh:
        return 'App PH';
      case NguonXin.appHs:
        return 'App HS';
      case NguonXin.gvNhap:
        return 'GV Nhập';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }
  String _getLopTenById(String idLop) {
    try {
      Lop lop = _lopList.firstWhere((lop) => lop.id == idLop);
      return lop.tenLop;
    } catch (e) {
      return idLop;
    }
  }
}
