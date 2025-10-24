import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/xin_ra_vao.dart';
import '../../../models/phan_cong_truc_ban.dart';
import '../../../services/xin_ra_vao_service.dart';
import '../../../services/phan_cong_truc_ban_service.dart';

class TrucBanScreen extends StatefulWidget {
  final String idGiaoVien;
  final String tenGiaoVien;

  const TrucBanScreen({
    super.key,
    required this.idGiaoVien,
    required this.tenGiaoVien,
  });

  @override
  State<TrucBanScreen> createState() => _TrucBanScreenState();
}

class _TrucBanScreenState extends State<TrucBanScreen>
    with SingleTickerProviderStateMixin {
  List<XinRaVao> _xinRaVaoList = [];
  bool _isLoading = true;
  bool _isTrucBanToday = true;
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkTrucBanStatus();
    _loadXinRaVaoToday();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkTrucBanStatus() async {
    try {
      final phanCongList = await PhanCongTrucBanService.getByTeacherId(widget.idGiaoVien);
      final today = DateTime.now();

      for (var phanCong in phanCongList) {
        if (phanCong.ngayTrucBan.any((date) =>
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day)) {
          setState(() {
            _isTrucBanToday = true;
          });
          break;
        }
      }
    } catch (e) {
      print('Error checking truc ban status: $e');
    }
  }

  Future<void> _loadXinRaVaoToday() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

      final list = await XinRaVaoService.getXinRaVaoByDateRange(startOfDay, endOfDay);

      setState(() {
        _xinRaVaoList = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Lỗi khi tải dữ liệu: $e');
    }
  }

  List<XinRaVao> _getFilteredList(TrangThaiXin? trangThai) {
    if (trangThai == null) return _xinRaVaoList;
    return _xinRaVaoList.where((x) => x.trangThai == trangThai).toList();
  }

  Future<void> _approveRequest(XinRaVao xinRaVao) async {
    try {
      final updatedRequest = xinRaVao.copyWith(
        trangThai: TrangThaiXin.daDuyet,
        nguoiDuyet: widget.idGiaoVien,
      );

      await XinRaVaoService.updateXinRaVao(xinRaVao.id!, updatedRequest);
      _loadXinRaVaoToday();
      _showSuccessSnackBar('Đã duyệt yêu cầu thành công');
    } catch (e) {
      _showErrorSnackBar('Lỗi khi duyệt yêu cầu: $e');
    }
  }

  Future<void> _rejectRequest(XinRaVao xinRaVao) async {
    final lyDoController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: lyDoController,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, lyDoController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final updatedRequest = xinRaVao.copyWith(
          trangThai: TrangThaiXin.tuChoi,
          nguoiDuyet: widget.idGiaoVien,
          lyDoTuChoi: result,
        );

        await XinRaVaoService.updateXinRaVao(xinRaVao.id!, updatedRequest);
        _loadXinRaVaoToday();
        _showSuccessSnackBar('Đã từ chối yêu cầu');
      } catch (e) {
        _showErrorSnackBar('Lỗi khi từ chối yêu cầu: $e');
      }
    }
  }

  Future<void> _confirmStudentReturn(XinRaVao xinRaVao) async {
    try {
      final updatedRequest = xinRaVao.copyWith(
        trangThai: TrangThaiXin.daVao,
        thoiGianVaoThucTe: DateTime.now(),
        nguoiDuyet: widget.idGiaoVien,
      );

      await XinRaVaoService.updateXinRaVao(xinRaVao.id!, updatedRequest);
      _loadXinRaVaoToday();
      _showSuccessSnackBar('Đã xác nhận học sinh vào lại');
    } catch (e) {
      _showErrorSnackBar('Lỗi khi xác nhận: $e');
    }
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
                _loadXinRaVaoToday();
              }
            },
            icon: const Icon(Icons.edit_calendar),
            label: const Text('Chọn ngày'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(XinRaVao xinRaVao) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getLoaiColor(xinRaVao.loai),
                  child: Icon(
                    _getLoaiIcon(xinRaVao.loai),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        xinRaVao.hoTenHs,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'SBD: ${xinRaVao.soTheHocSinh}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(height: 12),
            Text(
              'Loại: ${_getLoaiText(xinRaVao.loai)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text('Lý do: ${xinRaVao.lyDo}'),
            const SizedBox(height: 4),
            Text(
              'Thời gian xin: ${DateFormat('HH:mm dd/MM/yyyy').format(xinRaVao.thoiGianXin)}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (xinRaVao.thoiGianVaoDuKien != null)
              Text(
                'Dự kiến vào: ${DateFormat('HH:mm dd/MM/yyyy').format(xinRaVao.thoiGianVaoDuKien!)}',
                style: const TextStyle(color: Colors.grey),
              ),
            if (xinRaVao.thoiGianVaoThucTe != null)
              Text(
                'Vào thực tế: ${DateFormat('HH:mm dd/MM/yyyy').format(xinRaVao.thoiGianVaoThucTe!)}',
                style: const TextStyle(color: Colors.green),
              ),
            if (xinRaVao.lyDoTuChoi != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Lý do từ chối: ${xinRaVao.lyDoTuChoi}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_isTrucBanToday && xinRaVao.trangThai == TrangThaiXin.choDuyet)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _rejectRequest(xinRaVao),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _approveRequest(xinRaVao),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Duyệt', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ),
            if (_isTrucBanToday &&
                xinRaVao.trangThai == TrangThaiXin.daDuyet &&
                xinRaVao.loai == LoaiXin.xinRa)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmStudentReturn(xinRaVao),
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text('Xác nhận vào lại', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabView() {
    return Column(
      children: [
        if (!_isTrucBanToday)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Bạn không được phân công trực ban hôm nay',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Đã duyệt'),
            Tab(text: 'Tất cả'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListView(_getFilteredList(TrangThaiXin.choDuyet)),
              _buildListView(_getFilteredList(TrangThaiXin.daDuyet)),
              _buildListView(_getFilteredList(null)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<XinRaVao> list) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có yêu cầu nào',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadXinRaVaoToday,
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) => _buildRequestCard(list[index]),
      ),
    );
  }

  // Helper methods for UI
  String _getTrangThaiText(TrangThaiXin trangThai) {
    switch (trangThai) {
      case TrangThaiXin.choDuyet: return 'Chờ duyệt';
      case TrangThaiXin.daDuyet: return 'Đã duyệt';
      case TrangThaiXin.daVao: return 'Đã vào';
      case TrangThaiXin.tuChoi: return 'Từ chối';
    }
  }

  String _getLoaiText(LoaiXin loai) {
    switch (loai) {
      case LoaiXin.xinRa: return 'Xin ra ngoài';
      case LoaiXin.vaoLai: return 'Vào lại';
      case LoaiXin.tamNghi: return 'Tạm nghỉ';
    }
  }

  Color _getTrangThaiColor(TrangThaiXin trangThai) {
    switch (trangThai) {
      case TrangThaiXin.choDuyet: return Colors.orange;
      case TrangThaiXin.daDuyet: return Colors.green;
      case TrangThaiXin.daVao: return Colors.blue;
      case TrangThaiXin.tuChoi: return Colors.red;
    }
  }

  Color _getLoaiColor(LoaiXin loai) {
    switch (loai) {
      case LoaiXin.xinRa: return Colors.red;
      case LoaiXin.vaoLai: return Colors.blue;
      case LoaiXin.tamNghi: return Colors.orange;
    }
  }

  IconData _getLoaiIcon(LoaiXin loai) {
    switch (loai) {
      case LoaiXin.xinRa: return Icons.logout;
      case LoaiXin.vaoLai: return Icons.login;
      case LoaiXin.tamNghi: return Icons.pause;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trực ban - ${widget.tenGiaoVien}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildDatePicker(),
        ),
      ),
      body: _buildTabView(),
    );
  }
}