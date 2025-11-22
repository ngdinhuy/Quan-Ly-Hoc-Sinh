import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/hoc_sinh.dart';
import '../models/xin_ve_phep.dart';
import '../services/hoc_sinh_service.dart';
import '../services/xin_ve_phep_service.dart';
import '../utils/validation_utils.dart';

class GiaoVienNhapVePhepFormDialog extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final XinVePhep? xinVePhep;
  final String? idLop;

  const GiaoVienNhapVePhepFormDialog({
    super.key,
    required this.teacherId,
    required this.teacherName,
    this.xinVePhep,
    this.idLop,
  });

  @override
  State<GiaoVienNhapVePhepFormDialog> createState() =>
      _GiaoVienNhapVePhepFormDialogState();
}

class _GiaoVienNhapVePhepFormDialogState
    extends State<GiaoVienNhapVePhepFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _lyDoController = TextEditingController();
  final _tenNguoiDonController = TextEditingController();
  final _cccdNguoiDonController = TextEditingController();
  final _sdtNguoiDonController = TextEditingController();

  DateTime _ngayXinVe = DateTime.now();
  TimeOfDay _thoiGianXinVe = TimeOfDay.now();
  DateTime? _ngayXuongTruong;
  TimeOfDay? _thoiGianXuongTruong;

  HocSinh? _selectedStudent;
  List<DateTime> _availableMealDates = [];
  Set<DateTime> _selectedMealDates = {};
  bool _preApprove = false;
  bool _isSubmitting = false;
  bool _isSearching = false;

  bool get isEditing => widget.xinVePhep != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadEditingData();
    }
  }

  Future<void> _loadEditingData() async {
    final xinVePhep = widget.xinVePhep!;

    // Load student
    try {
      final student = await HocSinhService.getHocSinhById(xinVePhep.idHocSinh);
      if (student != null) {
        setState(() {
          _selectedStudent = student;
        });
      }
    } catch (e) {
      debugPrint('Error loading student: $e');
    }

    // Pre-fill form fields
    setState(() {
      _tenNguoiDonController.text = xinVePhep.tenNguoiDon;
      _cccdNguoiDonController.text = xinVePhep.cccdNguoiDon;
      _sdtNguoiDonController.text = xinVePhep.sdtNguoiDon;
      _lyDoController.text = xinVePhep.lyDo;

      // Set dates and times
      _ngayXinVe = xinVePhep.ngayXinVe;
      _thoiGianXinVe = TimeOfDay(
        hour: xinVePhep.thoiGianXinVe.hour,
        minute: xinVePhep.thoiGianXinVe.minute,
      );

      if (xinVePhep.ngayXuongTruong != null) {
        _ngayXuongTruong = xinVePhep.ngayXuongTruong;
        _thoiGianXuongTruong = xinVePhep.thoiGianXuongTruong != null
            ? TimeOfDay(
                hour: xinVePhep.thoiGianXuongTruong!.hour,
                minute: xinVePhep.thoiGianXuongTruong!.minute,
              )
            : null;
      }

      // Set pre-approve if already approved
      _preApprove = xinVePhep.trangThai == TrangThaiVePhep.daDuyet;
    });

    // Load meal dates - normalize to date-only (midnight) for comparison
    final savedMealDates = xinVePhep.danhSachNgayCatCom
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    _updateMealDatesForEditing(savedMealDates);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _lyDoController.dispose();
    _tenNguoiDonController.dispose();
    _cccdNguoiDonController.dispose();
    _sdtNguoiDonController.dispose();
    super.dispose();
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

  /// Update meal dates for editing mode - preserves previously selected dates
  void _updateMealDatesForEditing(Set<DateTime> savedMealDates) {
    if (_ngayXuongTruong != null) {
      final dates = generateMealDeductionDates(_ngayXinVe, _ngayXuongTruong);
      setState(() {
        _availableMealDates = dates;
        // Keep dates from available list that match saved dates (same object reference)
        _selectedMealDates = dates
            .where(
              (available) => savedMealDates.any(
                (saved) =>
                    available.year == saved.year &&
                    available.month == saved.month &&
                    available.day == saved.day,
              ),
            )
            .toSet();
      });
    } else {
      setState(() {
        _availableMealDates = [];
        _selectedMealDates = {};
      });
    }
  }

  Future<void> _showStudentListDialog() async {
    if (widget.idLop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có thông tin lớp học')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Load students by class
      final students = await HocSinhService.getHocSinhByLop(widget.idLop!);

      if (!mounted) return;

      setState(() {
        _isSearching = false;
      });

      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có học sinh trong lớp này')),
        );
        return;
      }

      // Show dialog with student list
      final selectedStudent = await showDialog<HocSinh>(
        context: context,
        builder: (context) => _StudentListDialog(students: students),
      );

      if (selectedStudent != null && mounted) {
        setState(() {
          _selectedStudent = selectedStudent;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: ${e.toString()}')),
        );
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectLeaveDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ngayXinVe,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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

    if (_selectedStudent == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn học sinh')));
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
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
        id: isEditing ? widget.xinVePhep!.id : null,
        idHocSinh: _selectedStudent!.id!,
        hoTenHocSinh: _selectedStudent!.hoTen,
        soTheHocSinh: _selectedStudent!.soTheHocSinh,
        idLop: _selectedStudent!.idLop,
        tenLop: _selectedStudent!.phongSo,
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
        nguon: isEditing ? widget.xinVePhep!.nguon : NguonVePhep.giaoVienNhap,
        tenPhuHuynh: isEditing ? widget.xinVePhep!.tenPhuHuynh : null,
        trangThai: _preApprove
            ? TrangThaiVePhep.daDuyet
            : TrangThaiVePhep.choDuyet,
        idNguoiDuyet: _preApprove
            ? widget.teacherId
            : (isEditing ? widget.xinVePhep!.idNguoiDuyet : null),
        tenNguoiDuyet: _preApprove
            ? widget.teacherName
            : (isEditing ? widget.xinVePhep!.tenNguoiDuyet : null),
        thoiGianDuyet: _preApprove
            ? DateTime.now()
            : (isEditing ? widget.xinVePhep!.thoiGianDuyet : null),
        lyDoTuChoi: isEditing ? widget.xinVePhep!.lyDoTuChoi : null,
        createdAt: isEditing ? widget.xinVePhep!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        await XinVePhepService.updateXinVePhep(xinVePhep.id!, xinVePhep);
      } else {
        await XinVePhepService.createXinVePhep(xinVePhep);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Đã cập nhật yêu cầu thành công!'
                  : _preApprove
                  ? 'Đã tạo và duyệt yêu cầu thành công!'
                  : 'Đã tạo yêu cầu thành công!',
            ),
          ),
        );
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing
                          ? 'Chỉnh sửa yêu cầu về phép'
                          : 'Tạo yêu cầu về phép',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStudentSearchSection(),
                      const SizedBox(height: 16),
                      if (_selectedStudent != null) ...[
                        _buildLeaveDatesSection(),
                        const SizedBox(height: 16),
                        _buildGuardianInfoSection(),
                        const SizedBox(height: 16),
                        if (_availableMealDates.isNotEmpty)
                          _buildMealDeductionSection(),
                        if (_availableMealDates.isNotEmpty)
                          const SizedBox(height: 16),
                        _buildReasonSection(),
                        const SizedBox(height: 16),
                        if (!isEditing) _buildPreApprovalSection(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSearchSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn học sinh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: isEditing
                  ? null
                  : (_isSearching ? null : _showStudentListDialog),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isEditing ? Colors.grey : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: isEditing ? Colors.grey.withAlpha(25) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_search,
                      color: isEditing ? Colors.grey : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing
                            ? 'Không thể thay đổi học sinh khi chỉnh sửa'
                            : (_selectedStudent != null
                                  ? _selectedStudent!.hoTen
                                  : 'Nhấn để chọn học sinh'),
                        style: TextStyle(
                          color: isEditing
                              ? Colors.grey
                              : (_selectedStudent != null
                                    ? Colors.black
                                    : Colors.grey[600]),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_isSearching)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.arrow_drop_down,
                        color: isEditing ? Colors.grey : Colors.green,
                      ),
                  ],
                ),
              ),
            ),
            if (_selectedStudent != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green,
                      child: _selectedStudent!.avatarFaceUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _selectedStudent!.avatarFaceUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.person),
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedStudent!.hoTen,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Thẻ: ${_selectedStudent!.soTheHocSinh} - Lớp: ${_selectedStudent!.phongSo}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedStudent = null;
                          _searchController.clear();
                        });
                      },
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

  Widget _buildLeaveDatesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thời gian về phép',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.green),
              title: const Text('Ngày xin về'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_ngayXinVe)),
              trailing: const Icon(Icons.edit),
              onTap: _selectLeaveDate,
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.green),
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin người đón',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
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
      elevation: 2,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${_selectedMealDates.length}/${_availableMealDates.length} ngày',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableMealDates.map((date) {
                final isSelected = _selectedMealDates.contains(date);
                debugPrint('huynd: ${isSelected} ${date}');
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
                  selectedColor: Colors.green.withAlpha(76),
                  checkmarkColor: Colors.green,
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lý do xin về phép',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lyDoController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do xin về phép...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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

  Widget _buildPreApprovalSection() {
    return Card(
      elevation: 2,
      color: Colors.amber.withAlpha(13),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'Tùy chọn duyệt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Duyệt luôn (bỏ qua quy trình duyệt)'),
              subtitle: const Text(
                'Yêu cầu sẽ được duyệt tự động và không cần chờ giáo viên khác duyệt',
                style: TextStyle(fontSize: 12),
              ),
              value: _preApprove,
              onChanged: (value) {
                setState(() {
                  _preApprove = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isSubmitting ? Colors.grey : Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Đang tạo...'),
                ],
              )
            : Text(
                isEditing
                    ? 'Cập nhật yêu cầu'
                    : _preApprove
                    ? 'Tạo và duyệt yêu cầu'
                    : 'Tạo yêu cầu',
              ),
      ),
    );
  }
}

/// Dialog to show list of students for selection
class _StudentListDialog extends StatefulWidget {
  final List<HocSinh> students;

  const _StudentListDialog({required this.students});

  @override
  State<_StudentListDialog> createState() => _StudentListDialogState();
}

class _StudentListDialogState extends State<_StudentListDialog> {
  final TextEditingController _filterController = TextEditingController();
  List<HocSinh> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _filteredStudents = widget.students;
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = widget.students;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredStudents = widget.students.where((student) {
          return student.hoTen.toLowerCase().contains(lowerQuery) ||
              student.soTheHocSinh.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chọn học sinh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search filter
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _filterController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên hoặc số thẻ...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: _filterStudents,
              ),
            ),
            // Student count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    'Tìm thấy ${_filteredStudents.length} học sinh',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Student list
            Expanded(
              child: _filteredStudents.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy học sinh',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: student.avatarFaceUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      student.avatarFaceUrl!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            student.hoTen,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Thẻ: ${student.soTheHocSinh} - Lớp: ${student.phongSo}',
                          ),
                          onTap: () => Navigator.pop(context, student),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
