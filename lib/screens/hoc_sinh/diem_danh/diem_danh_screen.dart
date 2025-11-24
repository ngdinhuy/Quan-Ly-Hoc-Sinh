import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/diem_danh.dart';
import '../../../models/lop.dart';
import '../../../services/diem_danh_service.dart';
import '../../../services/lop_service.dart';
import '../../../services/local_data_service.dart';
import '../../../services/hoc_sinh_service.dart';
import '../../../services/image_service.dart';
import '../../../widgets/face_camera_widget.dart';

class DiemDanhScreen extends StatefulWidget {
  const DiemDanhScreen({super.key});

  @override
  State<DiemDanhScreen> createState() => _DiemDanhScreenState();
}

class _DiemDanhScreenState extends State<DiemDanhScreen> {
  bool _isLoading = true;
  CaDiemDanh? _currentPeriod;
  CaHocConfig? _config;
  List<DiemDanh> _todayAttendance = [];
  String? _idHocSinh;
  String? _idLop;
  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _idHocSinh = LocalDataService.instance.getId();

      // Get student's class ID from student record
      if (_idHocSinh != null) {
        final student = await HocSinhService.getHocSinhById(_idHocSinh!);
        if (student != null) {
          _idLop = student.idLop;
        }
      }

      debugPrint('huynd idHocSinh $_idHocSinh');

      if (_idLop != null) {
        final lop = await LopService.getLopById(_idLop!);
        debugPrint('huynd idLop: $lop');
        _config = lop?.getConfigForToday() ?? CaHocConfig.defaultConfig();
        _currentPeriod = DiemDanhService.getCurrentPeriod(_config!);
      }

      if (_idHocSinh != null) {
        _todayAttendance = await DiemDanhService.getTodayByStudent(_idHocSinh!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _hasCheckedIn(CaDiemDanh period) {
    return _todayAttendance.any((d) => d.ca == period);
  }

  DiemDanh? _getCheckInForPeriod(CaDiemDanh period) {
    try {
      return _todayAttendance.firstWhere((d) => d.ca == period);
    } catch (e) {
      return null;
    }
  }

  Future<void> _checkIn(CaDiemDanh period, PhuongThucDiemDanh phuongThuc) async {
    if (_idHocSinh == null || _idLop == null) return;

    setState(() => _isCheckingIn = true);
    try {
      final result = await DiemDanhService.checkIn(
        idHocSinh: _idHocSinh!,
        idLop: _idLop!,
        ca: period,
        phuongThuc: phuongThuc,
      );

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Điểm danh thành công - ${result.trangThaiDisplayName}',
              ),
              backgroundColor: result.trangThai == TrangThaiDiemDanh.dungGio
                  ? Colors.green
                  : Colors.orange,
            ),
          );
        }
        await _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bạn đã điểm danh ca này rồi'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi điểm danh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCheckingIn = false);
    }
  }

  void _showFaceCheckIn(CaDiemDanh period) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Điểm danh bằng khuôn mặt')),
          body: FaceCameraWidget(
            overlayText: 'Đặt khuôn mặt vào khung và nhấn chụp',
            onCapture: (bytes) async {
              Navigator.pop(context);
              await _verifyFaceAndCheckIn(bytes, period);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _verifyFaceAndCheckIn(List<int> imageBytes, CaDiemDanh period) async {
    setState(() => _isCheckingIn = true);
    try {
      final response = await ImageService.uploadFaceImage(
        imageData: imageBytes,
        studentId: _idHocSinh!,
        isUpload: false,
      );

      if (response['is_match'] == true) {
        await _checkIn(period, PhuongThucDiemDanh.khuonMat);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xác thực khuôn mặt thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xác thực: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCheckingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm Danh'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current period info
                    _buildCurrentPeriodCard(),
                    const SizedBox(height: 24),

                    // Today's attendance status
                    const Text(
                      'Trạng thái hôm nay',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPeriodStatus(CaDiemDanh.sang, 'Ca Sáng', Icons.wb_sunny, Colors.orange),
                    _buildPeriodStatus(CaDiemDanh.trua, 'Ca Trưa', Icons.wb_cloudy, Colors.blue),
                    _buildPeriodStatus(CaDiemDanh.chieuToi, 'Ca Chiều Tối', Icons.nights_stay, Colors.indigo),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPeriodCard() {
    return Card(
      color: _currentPeriod != null ? Colors.blue.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _currentPeriod != null ? Icons.access_time : Icons.timer_off,
                  color: _currentPeriod != null ? Colors.blue : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentPeriod != null
                            ? 'Ca hiện tại: ${_getPeriodName(_currentPeriod!)}'
                            : 'Không có ca điểm danh',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_config != null && _currentPeriod != null)
                        Text(
                          'Thời gian: ${_getTimeRange(_currentPeriod!)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_currentPeriod != null && !_hasCheckedIn(_currentPeriod!)) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isCheckingIn
                          ? null
                          : () => _showFaceCheckIn(_currentPeriod!),
                      icon: const Icon(Icons.face),
                      label: const Text('Quét khuôn mặt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_currentPeriod != null && _hasCheckedIn(_currentPeriod!)) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Đã điểm danh ca này',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodStatus(
    CaDiemDanh period,
    String name,
    IconData icon,
    Color color,
  ) {
    final checkIn = _getCheckInForPeriod(period);
    final hasCheckedIn = checkIn != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(name),
        subtitle: hasCheckedIn
            ? Text(
                '${checkIn.trangThaiDisplayName} - ${DateFormat('HH:mm').format(checkIn.thoiGianCheckin)}',
              )
            : const Text('Chưa điểm danh'),
        trailing: hasCheckedIn
            ? Icon(
                checkIn.trangThai == TrangThaiDiemDanh.dungGio
                    ? Icons.check_circle
                    : checkIn.trangThai == TrangThaiDiemDanh.tre
                        ? Icons.warning
                        : Icons.event_busy,
                color: checkIn.trangThai == TrangThaiDiemDanh.dungGio
                    ? Colors.green
                    : checkIn.trangThai == TrangThaiDiemDanh.tre
                        ? Colors.orange
                        : Colors.grey,
              )
            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      ),
    );
  }

  String _getPeriodName(CaDiemDanh period) {
    switch (period) {
      case CaDiemDanh.sang:
        return 'Sáng';
      case CaDiemDanh.trua:
        return 'Trưa';
      case CaDiemDanh.chieuToi:
        return 'Chiều Tối';
    }
  }

  String _getTimeRange(CaDiemDanh period) {
    if (_config == null) return '';
    switch (period) {
      case CaDiemDanh.sang:
        return '${_config!.caSang.batDau} - ${_config!.caSang.ketThuc}';
      case CaDiemDanh.trua:
        return '${_config!.caTrua.batDau} - ${_config!.caTrua.ketThuc}';
      case CaDiemDanh.chieuToi:
        return '${_config!.caChieuToi.batDau} - ${_config!.caChieuToi.ketThuc}';
    }
  }
}
