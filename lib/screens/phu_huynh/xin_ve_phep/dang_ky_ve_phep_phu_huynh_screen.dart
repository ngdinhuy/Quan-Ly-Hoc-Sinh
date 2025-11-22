import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/hoc_sinh.dart';
import '../../../models/phu_huynh.dart';
import '../../../models/xin_ve_phep.dart';
import '../../../services/hoc_sinh_service.dart';
import '../../../services/local_data_service.dart';
import '../../../services/phu_huynh_service.dart';
import '../../../services/xin_ve_phep_service.dart';
import '../../../utils/validation_utils.dart';

class DangKyVePhepPhuHuynhScreen extends StatefulWidget {
  const DangKyVePhepPhuHuynhScreen({super.key});

  @override
  State<DangKyVePhepPhuHuynhScreen> createState() =>
      _DangKyVePhepPhuHuynhScreenState();
}

class _DangKyVePhepPhuHuynhScreenState
    extends State<DangKyVePhepPhuHuynhScreen> {
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
  PhuHuynh? _phuHuynh;
  List<DateTime> _availableMealDates = [];
  Set<DateTime> _selectedMealDates = {};

  final LocalDataService _localDataService = LocalDataService.instance;
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _lyDoController.dispose();
    _tenNguoiDonController.dispose();
    _cccdNguoiDonController.dispose();
    _sdtNguoiDonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final parentId = _localDataService.getId();
      if (parentId == null) {
        throw Exception('Không tìm thấy ID phụ huynh');
      }

      // Load parent information
      final phuHuynh = await PhuHuynhService.getPhuHuynhById(parentId);
      if (phuHuynh == null) {
        throw Exception('Không tìm thấy thông tin phụ huynh');
      }

      // Load child information
      final hocSinh = await HocSinhService.getHocSinhById(phuHuynh.idHs);
      if (hocSinh == null) {
        throw Exception('Không tìm thấy thông tin con');
      }

      // Auto-fill guardian information from parent profile
      _tenNguoiDonController.text = phuHuynh.hoTen;
      _cccdNguoiDonController.text = phuHuynh.soCccd;
      _sdtNguoiDonController.text = phuHuynh.soDienThoai;

      if (mounted) {
        setState(() {
          _phuHuynh = phuHuynh;
          _hocSinh = hocSinh;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _updateMealDates() {
    if (_ngayXuongTruong != null) {
      final dates = generateMealDeductionDates(_ngayXinVe, _ngayXuongTruong);
      setState(() {
        _availableMealDates = dates;
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

    if (_hocSinh == null || _phuHuynh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin cần thiết')),
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
        nguon: NguonVePhep.appPhuHuynh,
        tenPhuHuynh: _phuHuynh!.hoTen,
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Xin Về Phép Cho Con'),
          backgroundColor: Colors.orange,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Xin Về Phép Cho Con'),
          backgroundColor: Colors.orange,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xin Về Phép Cho Con'),
        backgroundColor: Colors.orange,
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
        backgroundColor: _isSubmitting ? Colors.grey : Colors.orange,
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
              'Thông tin con',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
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
              _buildInfoRow(Icons.class_, 'Lớp:', _hocSinh!.phongSo),
            ],
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
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.orange),
              title: const Text('Ngày xin về'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_ngayXinVe)),
              trailing: const Icon(Icons.edit),
              onTap: _selectLeaveDate,
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.orange),
              title: const Text('Giờ xin về'),
              subtitle: Text(_thoiGianXinVe.format(context)),
              trailing: const Icon(Icons.edit),
              onTap: _selectLeaveTime,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.event_available, color: Colors.orange),
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
                leading: const Icon(Icons.access_time, color: Colors.orange),
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
            const Row(
              children: [
                Text(
                  'Thông tin người đón',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '(Đã điền tự động)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tenNguoiDonController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên người đón *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên người đón';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cccdNguoiDonController,
              decoration: const InputDecoration(
                labelText: 'Số CCCD *',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
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
                  'Ngày cắt cơm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
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
                  label: Text(
                    DateFormat('dd/MM').format(date),
                    style: const TextStyle(fontSize: 12),
                  ),
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
                  selectedColor: Colors.orange.withAlpha(76),
                  checkmarkColor: Colors.orange,
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
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lyDoController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do xin về phép...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
