import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:quan_ly_hoc_sinh/models/giao_vien.dart';
import 'package:quan_ly_hoc_sinh/models/lop.dart';
import 'package:quan_ly_hoc_sinh/models/phan_cong_chu_nhiem.dart';
import 'package:quan_ly_hoc_sinh/services/giao_vien_service.dart';
import 'package:quan_ly_hoc_sinh/services/lop_service.dart';
import 'package:quan_ly_hoc_sinh/services/phan_cong_chu_nhiem_service.dart';

class PhanCongFormDialog extends StatefulWidget {
  final PhanCongChuNhiem? initialAssignment;
  final String? idTruong; // School ID for filtering classes

  const PhanCongFormDialog({
    Key? key,
    this.initialAssignment,
    this.idTruong,
  }) : super(key: key);

  @override
  State<PhanCongFormDialog> createState() => _PhanCongFormDialogState();
}

class _PhanCongFormDialogState extends State<PhanCongFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ghiChuController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  List<GiaoVien> _teachers = [];
  List<Lop> _classes = [];

  String? _selectedTeacherId;
  String? _selectedClassId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ghiChuController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load teachers
      _teachers = await GiaoVienService.getAllGiaoVien();

      // Load classes (filtered by school if provided)
      if (widget.idTruong != null) {
        _classes = await LopService.getLopByTruong(widget.idTruong!);
      } else {
        // Get all classes from all schools if no filter
        final snapshot = await FirebaseFirestore.instance.collection('lop').get();
        _classes = snapshot.docs.map((doc) => Lop.fromFirestore(doc)).toList();
      }

      // Set initial values if editing
      if (widget.initialAssignment != null) {
        _selectedTeacherId = widget.initialAssignment!.idGv;
        _selectedClassId = widget.initialAssignment!.idLop;
        _startDate = widget.initialAssignment!.tuNgay;
        _endDate = widget.initialAssignment!.denNgay;
        _ghiChuController.text = widget.initialAssignment!.ghiChu ?? '';
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Lỗi khi tải dữ liệu: $e');
    }
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTeacherId == null) {
      _showErrorMessage('Vui lòng chọn giáo viên');
      return;
    }

    if (_selectedClassId == null) {
      _showErrorMessage('Vui lòng chọn lớp');
      return;
    }

    try {
      setState(() => _isSaving = true);

      // Check if this class already has an active homeroom teacher
      final existingAssignments = await FirebaseFirestore.instance
          .collection('phan_cong_chu_nhiem')
          .where('id_lop', isEqualTo: _selectedClassId)
          .where('den_ngay', isNull: true) // Active assignments
          .get();

      // Only check for conflicts if creating new assignment or changing class
      if (widget.initialAssignment == null ||
          widget.initialAssignment!.idLop != _selectedClassId) {
        if (existingAssignments.docs.isNotEmpty) {
          final existingDoc = existingAssignments.docs.first;
          // Skip if this is the same record we're editing
          if (widget.initialAssignment == null ||
              existingDoc.id != widget.initialAssignment!.id) {
            setState(() => _isSaving = false);
            _showConflictDialog(existingDoc.id);
            return;
          }
        }
      }

      final assignment = PhanCongChuNhiem(
        id: widget.initialAssignment?.id,
        idGv: _selectedTeacherId!,
        idLop: _selectedClassId!,
        tuNgay: _startDate,
        denNgay: _endDate,
        ghiChu: _ghiChuController.text.isEmpty ? null : _ghiChuController.text,
        createdAt: widget.initialAssignment?.createdAt ?? DateTime.now(),
      );

      if (widget.initialAssignment == null) {
        // Create new assignment
        await PhanCongChuNhiemService.create(assignment);
        _showSuccessMessage('Thêm phân công chủ nhiệm thành công');
      } else {
        // Update existing assignment
        await PhanCongChuNhiemService.update(assignment);
        _showSuccessMessage('Cập nhật phân công chủ nhiệm thành công');
      }

      setState(() => _isSaving = false);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorMessage('Lỗi khi lưu phân công: $e');
    }
  }

  void _showConflictDialog(String existingAssignmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lớp đã có chủ nhiệm'),
        content: const Text(
            'Lớp này đã có giáo viên chủ nhiệm. Bạn có muốn kết thúc phân công hiện tại và thêm phân công mới?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                setState(() => _isSaving = true);

                // End the current assignment
                final existingDoc = await FirebaseFirestore.instance
                    .collection('phan_cong_chu_nhiem')
                    .doc(existingAssignmentId)
                    .get();

                if (existingDoc.exists) {
                  final existingAssignment = PhanCongChuNhiem.fromFirestore(existingDoc);
                  final updatedAssignment = existingAssignment.copyWith(
                    denNgay: DateTime.now(),
                  );
                  await PhanCongChuNhiemService.update(updatedAssignment);

                  // Now create the new assignment
                  final newAssignment = PhanCongChuNhiem(
                    idGv: _selectedTeacherId!,
                    idLop: _selectedClassId!,
                    tuNgay: _startDate,
                    denNgay: _endDate,
                    ghiChu: _ghiChuController.text.isEmpty ? null : _ghiChuController.text,
                    createdAt: DateTime.now(),
                  );

                  await PhanCongChuNhiemService.create(newAssignment);
                  _showSuccessMessage('Thêm phân công chủ nhiệm thành công');
                  if (mounted) Navigator.of(context).pop(true);
                }

                setState(() => _isSaving = false);
              } catch (e) {
                setState(() => _isSaving = false);
                _showErrorMessage('Lỗi khi cập nhật phân công: $e');
              }
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialAssignment != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        )
            : Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Sửa phân công chủ nhiệm' : 'Thêm phân công chủ nhiệm',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Teacher selection
                const Text(
                  'Giáo viên',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  hint: const Text('Chọn giáo viên'),
                  value: _selectedTeacherId,
                  onChanged: (value) {
                    setState(() => _selectedTeacherId = value);
                  },
                  items: _teachers.map((teacher) {
                    return DropdownMenuItem<String>(
                      value: teacher.id,
                      child: Text(teacher.hoTen),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Class selection
                const Text(
                  'Lớp học',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  hint: const Text('Chọn lớp'),
                  value: _selectedClassId,
                  onChanged: isEditing ? null : (value) {
                    setState(() => _selectedClassId = value);
                  },
                  items: _classes.map((classInfo) {
                    return DropdownMenuItem<String>(
                      value: classInfo.id,
                      child: Text('${classInfo.tenLop} (Phòng: ${classInfo.phongSo})'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Start date selection
                const Text(
                  'Ngày bắt đầu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // End date selection (optional)
                Row(
                  children: [
                    const Text(
                      'Ngày kết thúc',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(không bắt buộc)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() => _endDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _endDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                      : 'Chưa xác định',
                                ),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _endDate = null);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                const Text(
                  'Ghi chú',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ghiChuController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nhập ghi chú (không bắt buộc)',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // Submit buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveAssignment,
                      child: _isSaving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(isEditing ? 'Cập nhật' : 'Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
