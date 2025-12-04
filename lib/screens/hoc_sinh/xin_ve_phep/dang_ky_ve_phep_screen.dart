import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/hoc_sinh.dart';
import '../../../models/lop.dart';
import '../../../models/xin_ve_phep.dart';
import '../../../services/hoc_sinh_service.dart';
import '../../../services/local_data_service.dart';
import '../../../services/lop_service.dart';
import '../../../services/xin_ve_phep_service.dart';
import '../../../utils/validation_utils.dart';

class DangKyVePhepScreen extends StatefulWidget {
  const DangKyVePhepScreen({super.key});

  @override
  State<DangKyVePhepScreen> createState() => _DangKyVePhepScreenState();
}

class _DangKyVePhepScreenState extends State<DangKyVePhepScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lyDoController = TextEditingController();
  final _tenNguoiDonController = TextEditingController();
  final _cccdNguoiDonController = TextEditingController();
  final _sdtNguoiDonController = TextEditingController();

  DateTime _ngayXinVe = DateTime.now();
  TimeOfDay _thoiGianXinVe = TimeOfDay.now();
  DateTime? _ngayXuongTruong;
  TimeOfDay? _thoiGianXuongTruong;

  HocSinh? _hocSinh;
  Lop? _lop;
  List<DateTime> _availableMealDates = [];
  Set<DateTime> _selectedMealDates = {};

  final LocalDataService _localDataService = LocalDataService.instance;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchHocSinh();
  }

  @override
  void dispose() {
    _lyDoController.dispose();
    _tenNguoiDonController.dispose();
    _cccdNguoiDonController.dispose();
    _sdtNguoiDonController.dispose();
    super.dispose();
  }

  Future<void> _fetchHocSinh() async {
    if (_localDataService.getId() == null) return;
    HocSinh? fetchedHocSinh = await HocSinhService.getHocSinhById(
      _localDataService.getId()!,
    );
    if (mounted) {
      setState(() {
        _hocSinh = fetchedHocSinh;
      });

      // Load class information
      if (fetchedHocSinh != null && fetchedHocSinh.idLop.isNotEmpty) {
        final lop = await LopService.getLopById(fetchedHocSinh.idLop);
        if (mounted) {
          setState(() {
            _lop = lop;
          });
        }
      }
    }
  }

  void _updateMealDates() {
    if (_ngayXuongTruong != null) {
      final dates = generateMealDeductionDates(_ngayXinVe, _ngayXuongTruong);
      setState(() {
        _availableMealDates = dates;
        // Default: select all dates
        _selectedMealDates = Set.from(dates);
      });
    } else {
      setState(() {
        _availableMealDates = [];
        _selectedMealDates = {};
      });
    }
  }

  Future<void> _selectLeaveDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ngayXinVe,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _ngayXinVe = picked;
        // Reset return date if it's before leave date
        if (_ngayXuongTruong != null &&
            _ngayXuongTruong!.isBefore(_ngayXinVe)) {
          _ngayXuongTruong = null;
          _thoiGianXuongTruong = null;
        }
        _updateMealDates();
      });
    }
  }

  Future<void> _selectReturnDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ngayXuongTruong ?? _ngayXinVe.add(const Duration(days: 1)),
      firstDate: _ngayXinVe,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _ngayXuongTruong = picked;
        _updateMealDates();
      });
    }
  }

  Future<void> _selectLeaveTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _thoiGianXinVe,
    );

    if (picked != null) {
      setState(() {
        _thoiGianXinVe = picked;
      });
    }
  }

  Future<void> _selectReturnTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _thoiGianXuongTruong ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _thoiGianXuongTruong = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_hocSinh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin học sinh')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final thoiGianXinVe = DateTime(
        _ngayXinVe.year,
        _ngayXinVe.month,
        _ngayXinVe.day,
        _thoiGianXinVe.hour,
        _thoiGianXinVe.minute,
      );

      DateTime? thoiGianXuongTruong;
      if (_ngayXuongTruong != null && _thoiGianXuongTruong != null) {
        thoiGianXuongTruong = DateTime(
          _ngayXuongTruong!.year,
          _ngayXuongTruong!.month,
          _ngayXuongTruong!.day,
          _thoiGianXuongTruong!.hour,
          _thoiGianXuongTruong!.minute,
        );
      }

      final xinVePhep = XinVePhep(
        idHocSinh: _hocSinh!.id!,
        hoTenHocSinh: _hocSinh!.hoTen,
        soTheHocSinh: _hocSinh!.soTheHocSinh,
        idLop: _hocSinh!.idLop,
        tenLop: _hocSinh!.phongSo,
        lyDo: _lyDoController.text.trim(),
        thoiGianXinVe: thoiGianXinVe,
        ngayXinVe: DateTime(_ngayXinVe.year, _ngayXinVe.month, _ngayXinVe.day),
        thoiGianXuongTruong: thoiGianXuongTruong,
        ngayXuongTruong: _ngayXuongTruong != null
            ? DateTime(
                _ngayXuongTruong!.year,
                _ngayXuongTruong!.month,
                _ngayXuongTruong!.day,
              )
            : null,
        tenNguoiDon: _tenNguoiDonController.text.trim(),
        cccdNguoiDon: _cccdNguoiDonController.text.trim(),
        sdtNguoiDon: _sdtNguoiDonController.text.trim(),
        danhSachNgayCatCom: _selectedMealDates.toList(),
        nguon: NguonVePhep.appHocSinh,
        createdAt: DateTime.now(),
      );

      await XinVePhepService.createXinVePhep(xinVePhep);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi yêu cầu thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xin Về Phép'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStudentInfoSection(),
              const SizedBox(height: 16),
              _buildLeaveDatesSection(),
              const SizedBox(height: 16),
              _buildGuardianInfoSection(),
              const SizedBox(height: 16),
              if (_availableMealDates.isNotEmpty) _buildMealDeductionSection(),
              if (_availableMealDates.isNotEmpty) const SizedBox(height: 16),
              _buildReasonSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _handleSubmit,
        backgroundColor: _isSubmitting ? Colors.grey : Colors.blue,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send),
        label: Text(_isSubmitting ? 'Đang gửi...' : 'Gửi yêu cầu'),
      ),
    );
  }

  Widget _buildStudentInfoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin học sinh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            if (_hocSinh != null) ...[
              _buildInfoRow(Icons.person, 'Họ và tên:', _hocSinh!.hoTen),
              _buildInfoRow(
                Icons.credit_card,
                'Số thẻ:',
                _hocSinh!.soTheHocSinh,
              ),
              _buildInfoRow(
                  Icons.class_, 'Lớp:', _lop?.tenLop ?? _hocSinh!.idLop),
            ] else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveDatesSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thời gian về phép',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Ngày xin về'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_ngayXinVe)),
              trailing: const Icon(Icons.edit),
              onTap: _selectLeaveDate,
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.blue),
              title: const Text('Giờ xin về'),
              subtitle: Text(_thoiGianXinVe.format(context)),
              trailing: const Icon(Icons.edit),
              onTap: _selectLeaveTime,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.event_available, color: Colors.green),
              title: const Text('Ngày xuống trường (tùy chọn)'),
              subtitle: Text(
                _ngayXuongTruong != null
                    ? DateFormat('dd/MM/yyyy').format(_ngayXuongTruong!)
                    : 'Chưa chọn',
              ),
              trailing: const Icon(Icons.edit),
              onTap: _selectReturnDate,
            ),
            if (_ngayXuongTruong != null)
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.green),
                title: const Text('Giờ xuống trường'),
                subtitle: Text(
                  _thoiGianXuongTruong?.format(context) ?? 'Chưa chọn',
                ),
                trailing: const Icon(Icons.edit),
                onTap: _selectReturnTime,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardianInfoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin người đón',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tenNguoiDonController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên người đón *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên người đón';
                }
                if (value.trim().length < 3) {
                  return 'Tên phải có ít nhất 3 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cccdNguoiDonController,
              decoration: const InputDecoration(
                labelText: 'Số CCCD (12 số) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
              maxLength: 12,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số CCCD';
                }
                if (!isValidCCCD(value.trim())) {
                  return 'CCCD phải có đúng 12 chữ số';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sdtNguoiDonController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                if (!isValidVietnamesePhone(value.trim())) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealDeductionSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn ngày cắt cơm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '${_selectedMealDates.length}/${_availableMealDates.length} ngày',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn các ngày cần cắt cơm trong thời gian nghỉ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableMealDates.map((date) {
                final isSelected = _selectedMealDates.contains(date);
                return FilterChip(
                  label: Text(DateFormat('dd/MM').format(date)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedMealDates.add(date);
                      } else {
                        _selectedMealDates.remove(date);
                      }
                    });
                  },
                  selectedColor: Colors.blue.withAlpha(76),
                  checkmarkColor: Colors.blue,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lý do xin về phép',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lyDoController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do xin về phép...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập lý do';
                }
                if (value.trim().length < 10) {
                  return 'Lý do phải có ít nhất 10 ký tự';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
