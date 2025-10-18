import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/tham_ph.dart';
import '../../../services/tham_ph_service.dart';
import '../../../services/hoc_sinh_service.dart';

class DanhSachThamConScreen extends StatefulWidget {
  final String idHocSinh;
  final String tenHocSinh;

  const DanhSachThamConScreen({
    Key? key,
    required this.idHocSinh,
    required this.tenHocSinh,
  }) : super(key: key);

  @override
  State<DanhSachThamConScreen> createState() => _DanhSachThamConScreenState();
}

class _DanhSachThamConScreenState extends State<DanhSachThamConScreen> {
  bool _isLoading = true;
  List<ThamPh> _visits = [];
  String? _errorMessage;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load all visits for this student
      final visits = await ThamPhService.getThamPhByHs(widget.idHocSinh);

      setState(() {
        _visits = visits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours giờ ${minutes > 0 ? '$minutes phút' : ''}';
    } else {
      return '$minutes phút';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lịch sử thăm ${widget.tenHocSinh}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVisits,
            tooltip: "Làm mới",
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? _buildErrorView()
          : _visits.isEmpty
            ? _buildEmptyState()
            : _buildVisitsList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 70, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Không thể tải dữ liệu',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadVisits,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "Chưa có lần thăm nào",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "Bạn chưa có lịch sử thăm học sinh này",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _visits.length,
      itemBuilder: (context, index) {
        final visit = _visits[index];
        return _buildVisitCard(visit);
      },
    );
  }

  Widget _buildVisitCard(ThamPh visit) {
    final bool isCompleted = visit.trangThai == TrangThaiTham.daVe;
    final Color statusColor = isCompleted ? Colors.blue : Colors.green;

    // Calculate visit duration if completed
    Duration? duration;
    if (isCompleted && visit.thoiGianKetThuc != null) {
      duration = visit.thoiGianKetThuc!.difference(visit.thoiGianDen);
    }

    // Group visits by date
    final bool showDateHeader = index == 0 ||
        !_isSameDay(_visits[index - 1].thoiGianDen, visit.thoiGianDen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDateHeader) _buildDateHeader(visit.thoiGianDen),
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isCompleted ? Colors.transparent : Colors.green.shade200,
              width: isCompleted ? 0 : 1,
            ),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle : Icons.access_time,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCompleted ? "Đã hoàn thành" : "Đang thăm",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Phòng: ${visit.phongSo}",
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (duration != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Thời gian đến",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _timeFormat.format(visit.thoiGianDen),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Text(
                              "Thời gian ra về",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              visit.thoiGianKetThuc != null
                                ? _timeFormat.format(visit.thoiGianKetThuc!)
                                : "Chưa rời đi",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: visit.thoiGianKetThuc != null
                                  ? Colors.black
                                  : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16, left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  _dateFormat.format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Used in _buildVisitsList to access index
  int get index => _visits.indexWhere((visit) => visit.id == _visits[0].id);
}