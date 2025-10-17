import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/tham_ph.dart';
import '../../../models/lop.dart';
import '../../../services/tham_ph_service.dart';
import '../../../services/lop_service.dart';
import '../../../services/hoc_sinh_service.dart';

class DanhSachPhuHuynhThamScreen extends StatefulWidget {
  final String idLop;
  final String tenLop;
  const DanhSachPhuHuynhThamScreen({super.key, required this.idLop, required this.tenLop});

  @override
  State<DanhSachPhuHuynhThamScreen> createState() => _DanhSachPhuHuynhThamScreenState();
}

class _DanhSachPhuHuynhThamScreenState extends State<DanhSachPhuHuynhThamScreen> {
  bool _isLoading = true;
  List<ThamPh> _visitsAll = [];
  List<ThamPh> _visitsFiltered = [];
  TrangThaiTham? _selectedStatus;
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      setState(() => _isLoading = true);

      // Get student IDs from this class
      final students = await HocSinhService.getHocSinhByLop(widget.idLop);
      final studentIds = students.map((student) => student.id!).toList();

      // Get all parent visits for these students
      List<ThamPh> allVisits = [];
      for (String studentId in studentIds) {
        final visits = await ThamPhService.getThamPhByHs(studentId);
        allVisits.addAll(visits);
      }

      // Sort by visit time (newest first)
      allVisits.sort((a, b) => b.thoiGianDen.compareTo(a.thoiGianDen));

      setState(() {
        _visitsAll = allVisits;
        _visitsFiltered = allVisits;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar("Lỗi khi tải dữ liệu: $e");
    }
  }

  void _applyFilters() {
    List<ThamPh> filtered = List.from(_visitsAll);

    // Apply status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((visit) => visit.trangThai == _selectedStatus).toList();
    }

    // Apply date filter
    if (_selectedDate != null) {
      filtered = filtered.where((visit) {
        return visit.thoiGianDen.year == _selectedDate!.year &&
            visit.thoiGianDen.month == _selectedDate!.month &&
            visit.thoiGianDen.day == _selectedDate!.day;
      }).toList();
    }

    // Apply search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((visit) =>
      visit.hoTenPh.toLowerCase().contains(query) ||
          visit.hoTenHs.toLowerCase().contains(query) ||
          visit.soDienThoai.toLowerCase().contains(query) ||
          visit.soCccd.toLowerCase().contains(query)
      ).toList();
    }

    setState(() {
      _visitsFiltered = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedStatus = null;
      _searchController.clear();
      _visitsFiltered = _visitsAll;
    });
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _applyFilters();
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _updateStatus(ThamPh visit, TrangThaiTham newStatus) async {
    try {
      final updatedVisit = visit.copyWith(
        trangThai: newStatus,
        thoiGianKetThuc: newStatus == TrangThaiTham.daVe ? DateTime.now() : visit.thoiGianKetThuc,
      );

      await ThamPhService.updateThamPh(visit.id!, updatedVisit);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật trạng thái thành công")),
      );

      // Refresh data
      _initData();

    } catch (e) {
      _showErrorSnackbar("Lỗi khi cập nhật: $e");
    }
  }

  void _showVisitDetails(ThamPh visit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Chi tiết thăm lớp",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              _buildDetailItem("Phụ huynh", visit.hoTenPh),
              _buildDetailItem("Học sinh", visit.hoTenHs),
              _buildDetailItem("Số CCCD", visit.soCccd),
              _buildDetailItem("Số điện thoại", visit.soDienThoai),
              _buildDetailItem("Phòng thăm", visit.phongSo),
              _buildDetailItem("Thời gian đến", "${_dateFormat.format(visit.thoiGianDen)} ${_timeFormat.format(visit.thoiGianDen)}"),
              if (visit.thoiGianKetThuc != null)
                _buildDetailItem("Thời gian kết thúc", "${_dateFormat.format(visit.thoiGianKetThuc!)} ${_timeFormat.format(visit.thoiGianKetThuc!)}"),
              _buildDetailItem("Trạng thái", visit.trangThai == TrangThaiTham.dangTham ? "Đang thăm" : "Đã về"),

              const SizedBox(height: 20),

              if (visit.trangThai == TrangThaiTham.dangTham)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Đánh dấu đã về"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateStatus(visit, TrangThaiTham.daVe);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Danh sách phụ huynh thăm"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Thăm - ${widget.tenLop ?? 'Lớp'}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initData,
            tooltip: "Làm mới",
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          _buildFilterBar(),

          // Chips for active filters
          _buildActiveFilters(),

          // List of visits
          Expanded(
            child: _visitsFiltered.isEmpty
                ? _buildEmptyState()
                : _buildVisitList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Tìm kiếm phụ huynh, học sinh...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _applyFilters();
                },
              )
                  : null,
            ),
            onChanged: (value) {
              _applyFilters();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Status filter
              Expanded(
                child: DropdownButtonFormField<TrangThaiTham?>(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: "Trạng thái",
                  ),
                  value: _selectedStatus,
                  items: [
                    const DropdownMenuItem<TrangThaiTham?>(
                      value: null,
                      child: Text("Tất cả trạng thái"),
                    ),
                    const DropdownMenuItem<TrangThaiTham?>(
                      value: TrangThaiTham.dangTham,
                      child: Text("Đang thăm"),
                    ),
                    const DropdownMenuItem<TrangThaiTham?>(
                      value: TrangThaiTham.daVe,
                      child: Text("Đã về"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Date filter
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate != null
                              ? _dateFormat.format(_selectedDate!)
                              : "Chọn ngày",
                          style: TextStyle(
                            color: _selectedDate != null ? Colors.black : Colors.grey,
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    if (_selectedStatus == null && _selectedDate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedStatus != null)
            Chip(
              label: Text(_selectedStatus == TrangThaiTham.dangTham ? "Đang thăm" : "Đã về"),
              onDeleted: () {
                setState(() {
                  _selectedStatus = null;
                });
                _applyFilters();
              },
              backgroundColor: Colors.blue.shade100,
            ),

          if (_selectedDate != null)
            Chip(
              label: Text(_dateFormat.format(_selectedDate!)),
              onDeleted: () {
                setState(() {
                  _selectedDate = null;
                });
                _applyFilters();
              },
              backgroundColor: Colors.green.shade100,
            ),

          if (_selectedStatus != null || _selectedDate != null)
            Chip(
              label: const Text("Xóa tất cả"),
              onDeleted: _clearFilters,
              deleteIcon: const Icon(Icons.clear_all),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "Không có phụ huynh thăm",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _selectedStatus != null || _selectedDate != null
                ? "Thử thay đổi bộ lọc để xem kết quả khác"
                : "Khi có phụ huynh đến thăm, họ sẽ xuất hiện ở đây",
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVisitList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      itemCount: _visitsFiltered.length,
      itemBuilder: (context, index) {
        final visit = _visitsFiltered[index];
        return _buildVisitCard(visit);
      },
    );
  }

  Widget _buildVisitCard(ThamPh visit) {
    final bool isOngoing = visit.trangThai == TrangThaiTham.dangTham;
    final Color statusColor = isOngoing ? Colors.green : Colors.grey;
    final Duration? duration = visit.thoiGianKetThuc != null
        ? visit.thoiGianKetThuc!.difference(visit.thoiGianDen)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOngoing ? Colors.green.shade200 : Colors.transparent,
          width: isOngoing ? 1 : 0,
        ),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _showVisitDetails(visit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    foregroundColor: statusColor,
                    radius: 24,
                    child: Icon(
                      isOngoing ? Icons.person : Icons.how_to_reg,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.hoTenPh,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Phụ huynh của ${visit.hoTenHs}",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visit.soDienThoai,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOngoing ? "Đang thăm" : "Đã về",
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.login,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Đến: ${_timeFormat.format(visit.thoiGianDen)} ${_dateFormat.format(visit.thoiGianDen)}",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      if (visit.thoiGianKetThuc != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.logout,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Về: ${_timeFormat.format(visit.thoiGianKetThuc!)} ${_dateFormat.format(visit.thoiGianKetThuc!)}",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (duration != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${duration.inHours}h ${duration.inMinutes.remainder(60)}m",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              if (isOngoing) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(visit, TrangThaiTham.daVe),
                  icon: const Icon(Icons.logout),
                  label: const Text("Đánh dấu đã về"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
