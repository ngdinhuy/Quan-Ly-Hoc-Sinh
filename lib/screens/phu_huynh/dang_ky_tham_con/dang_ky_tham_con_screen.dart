import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/hoc_sinh.dart';
import '../../../models/phu_huynh.dart';
import '../../../models/tham_ph.dart';
import '../../../services/hoc_sinh_service.dart';
import '../../../services/phu_huynh_service.dart';
import '../../../services/tham_ph_service.dart';

class DangKyThamConScreen extends StatefulWidget {
  final String idHocSinh;
  final String idPhuHuynh;

  const DangKyThamConScreen({
    Key? key,
    required this.idHocSinh,
    required this.idPhuHuynh,
  }) : super(key: key);

  @override
  State<DangKyThamConScreen> createState() => _DangKyThamConScreenState();
}

class _DangKyThamConScreenState extends State<DangKyThamConScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  HocSinh? _hocSinh;
  PhuHuynh? _phuHuynh;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load student data
      final hocSinh = await HocSinhService.getHocSinhById(widget.idHocSinh);
      if (hocSinh == null) {
        throw Exception("Không tìm thấy thông tin học sinh");
      }

      // Load parent data
      final phuHuynh = await PhuHuynhService.getPhuHuynhById(widget.idPhuHuynh);
      if (phuHuynh == null) {
        throw Exception("Không tìm thấy thông tin phụ huynh");
      }

      // Set default date to tomorrow
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      // Set default time to 9:00 AM
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);

      setState(() {
        _hocSinh = hocSinh;
        _phuHuynh = phuHuynh;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    // Don't allow selecting dates in the past
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Chọn ngày thăm',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Chọn giờ thăm',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isSubmitting = true;
          _errorMessage = null;
        });

        // Combine date and time
        final DateTime visitDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        // Check if date/time is valid (not in the past)
        final now = DateTime.now();
        if (visitDateTime.isBefore(now)) {
          throw Exception('Thời gian thăm không thể trong quá khứ');
        }

        // Create visit record
        final ThamPh thamPh = ThamPh(
          idPh: _phuHuynh!.id!,
          hoTenPh: _phuHuynh!.hoTen,
          soCccd: _phuHuynh!.soCccd,
          soDienThoai: _phuHuynh!.soDienThoai,
          idHs: _hocSinh!.id!,
          hoTenHs: _hocSinh!.hoTen,
          phongSo: _hocSinh!.phongSo,
          thoiGianDen: visitDateTime,
          trangThai: TrangThaiTham.dangTham,
          createdAt: DateTime.now(),
        );

        await ThamPhService.createThamPh(thamPh);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thăm thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return success
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Đăng ký thăm con")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Đăng ký thăm con")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                "Đã xảy ra lỗi",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Đăng ký thăm con"),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildVisitTimeSection(),
              const SizedBox(height: 24),
              _buildNoteSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Thông tin thăm",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Học sinh:", _hocSinh!.hoTen),
            _buildInfoRow("Phòng:", _hocSinh!.phongSo),
            _buildInfoRow("Phụ huynh:", _phuHuynh!.hoTen),
            _buildInfoRow("Quan hệ:", _phuHuynh!.quanHe),
            _buildInfoRow("CCCD:", _phuHuynh!.soCccd),
            _buildInfoRow("Số điện thoại:", _phuHuynh!.soDienThoai),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Thời gian thăm",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Ngày thăm",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(_dateFormat.format(_selectedDate)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Giờ thăm",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.access_time),
                  ),
                  child: Text(_formatTimeOfDay(_selectedTime)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ghi chú",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Nhập ghi chú (nếu có)",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Đăng ký thăm",
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}