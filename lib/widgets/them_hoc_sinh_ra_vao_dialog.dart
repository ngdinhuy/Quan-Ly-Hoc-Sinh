import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/xin_ra_vao.dart';
import '../models/hoc_sinh.dart';
import '../services/xin_ra_vao_service.dart';
import '../services/hoc_sinh_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemHocSinhRaVaoDialog extends StatefulWidget {
  final String idLop;
  final Function()? onSuccess;

  const ThemHocSinhRaVaoDialog({
    Key? key,
    required this.idLop,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<ThemHocSinhRaVaoDialog> createState() => _ThemHocSinhRaVaoDialogState();
}

class _ThemHocSinhRaVaoDialogState extends State<ThemHocSinhRaVaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _studentCardController = TextEditingController();
  final _reasonController = TextEditingController();
  final _searchController = TextEditingController();

  LoaiXin _selectedType = LoaiXin.xinRa;
  DateTime _exitTime = DateTime.now();
  DateTime? _expectedReturnTime;

  bool _isLoading = false;
  bool _isLoadingStudents = true;
  String? _errorMessage;
  List<HocSinh> _students = [];
  List<HocSinh> _filteredStudents = [];
  bool _showStudentSelector = false;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final NguonXin _source = NguonXin.gvNhap; // Teacher input as source

  @override
  void initState() {
    super.initState();
    _loadStudentsForClass();
  }

  Future<void> _loadStudentsForClass() async {
    try {
      setState(() {
        _isLoadingStudents = true;
      });

      final students = await HocSinhService.getHocSinhByLop(widget.idLop);
      setState(() {
        _students = students;
        _filteredStudents = students;
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách học sinh: $e';
        _isLoadingStudents = false;
      });
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _studentNameController.dispose();
    _studentCardController.dispose();
    _reasonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredStudents = _students;
      });
      return;
    }

    setState(() {
      _filteredStudents = _students.where((student) {
        final nameLower = student.hoTen.toLowerCase();
        final idLower = student.id?.toLowerCase() ?? '';
        final cardLower = student.soTheHocSinh.toLowerCase();
        final queryLower = query.toLowerCase();

        return nameLower.contains(queryLower) ||
            idLower.contains(queryLower) ||
            cardLower.contains(queryLower);
      }).toList();
    });
  }

  void _selectStudent(HocSinh student) {
    setState(() {
      _studentIdController.text = student.id ?? '';
      _studentNameController.text = student.hoTen;
      _studentCardController.text = student.soTheHocSinh;
      _showStudentSelector = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thêm thông tin ra vào',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                _showStudentSelector
                    ? _buildStudentSelector()
                    : _buildStudentSection(),
                const SizedBox(height: 16),
                _buildTypeSection(),
                const SizedBox(height: 16),
                _buildTimeSection(),
                const SizedBox(height: 16),
                _buildReasonSection(),
                const SizedBox(height: 24),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn học sinh',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _isLoadingStudents
            ? const Center(child: CircularProgressIndicator())
            : _filteredStudents.isEmpty
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Không tìm thấy học sinh'),
          ),
        )
            : Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: _filteredStudents.length,
            itemBuilder: (context, index) {
              final student = _filteredStudents[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(student.hoTen.substring(0, 1)),
                ),
                title: Text(student.hoTen),
                subtitle: Text('Thẻ: ${student.soTheHocSinh}'),
                onTap: () => _selectStudent(student),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Thông tin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('Chọn từ danh sách'),
              onPressed: () {
                setState(() {
                  _showStudentSelector = true;
                  _searchController.clear();
                  _filteredStudents = _students;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _studentIdController,
          decoration: const InputDecoration(
            labelText: 'Mã học sinh',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.perm_identity),
          ),
          readOnly: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn học sinh';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _studentNameController,
          decoration: const InputDecoration(
            labelText: 'Tên học sinh',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          readOnly: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn học sinh';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _studentCardController,
          decoration: const InputDecoration(
            labelText: 'Số thẻ học sinh',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.credit_card),
          ),
          readOnly: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn học sinh';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loại xin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<LoaiXin>(
          segments: const [
            ButtonSegment<LoaiXin>(
              value: LoaiXin.xinRa,
              label: Text('Xin ra'),
              icon: Icon(Icons.exit_to_app),
            ),
            ButtonSegment<LoaiXin>(
              value: LoaiXin.vaoLai,
              label: Text('Vào lại'),
              icon: Icon(Icons.login),
            ),
            ButtonSegment<LoaiXin>(
              value: LoaiXin.tamNghi,
              label: Text('Tạm nghỉ'),
              icon: Icon(Icons.sick),
            ),
          ],
          selected: {_selectedType},
          onSelectionChanged: (Set<LoaiXin> selection) {
            if (selection.isNotEmpty) {
              setState(() {
                _selectedType = selection.first;

                // Reset expected return time if type is temporary leave
                if (_selectedType == LoaiXin.tamNghi) {
                  _expectedReturnTime = null;
                }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin thời gian',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('Thời gian xin'),
          subtitle: Text(
            '${_dateFormat.format(_exitTime)} ${_timeFormat.format(_exitTime)}',
          ),
          leading: const Icon(Icons.access_time),
          trailing: const Icon(Icons.edit),
          onTap: _selectExitTime,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),

        if (_selectedType != LoaiXin.tamNghi) ...[
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Thời gian vào dự kiến'),
            subtitle: _expectedReturnTime != null
                ? Text('${_dateFormat.format(_expectedReturnTime!)} ${_timeFormat.format(_expectedReturnTime!)}')
                : const Text('Chưa chọn'),
            leading: const Icon(Icons.schedule),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_expectedReturnTime != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _expectedReturnTime = null;
                      });
                    },
                  ),
                const Icon(Icons.edit),
              ],
            ),
            onTap: _selectReturnTime,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lý do',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: 'Lý do xin ra/vào',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.subject),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập lý do';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Text('Lưu'),
        ),
      ],
    );
  }

  Future<void> _selectExitTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _exitTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_exitTime),
      );

      if (pickedTime != null) {
        setState(() {
          _exitTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _selectReturnTime() async {
    final initialDate = _expectedReturnTime ?? _exitTime;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        setState(() {
          _expectedReturnTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Validate time logic
        if (_selectedType != LoaiXin.tamNghi &&
            _expectedReturnTime != null &&
            _expectedReturnTime!.isBefore(_exitTime)) {
          throw Exception('Thời gian vào dự kiến phải sau thời gian xin ra');
        }

        // Create the entry/exit record
        final XinRaVao xinRaVao = XinRaVao(
          idHs: _studentIdController.text.trim(),
          hoTenHs: _studentNameController.text.trim(),
          soTheHocSinh: _studentCardController.text.trim(),
          idLop: widget.idLop,
          lyDo: _reasonController.text.trim(),
          nguon: _source,
          loai: _selectedType,
          thoiGianXin: _exitTime,
          thoiGianVaoDuKien: _expectedReturnTime,
          trangThai: TrangThaiXin.daDuyet, // Auto-approve when teacher adds
          nguoiDuyet: FirebaseAuth.instance.currentUser?.uid,
          createdAt: DateTime.now(),
        );

        // Save to Firestore
        await XinRaVaoService.createXinRaVao(xinRaVao);

        // Close dialog and notify parent
        if (mounted) {
          Navigator.of(context).pop();
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm thông tin ra vào')),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Lỗi: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
}
