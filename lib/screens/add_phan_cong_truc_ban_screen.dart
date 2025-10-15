import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/phan_cong_truc_ban.dart';
import '../models/truong.dart';
import '../models/giao_vien.dart';
import '../services/phan_cong_truc_ban_service.dart';
import '../services/truong_service.dart';
import '../services/giao_vien_service.dart';

class AddEditPhanCongTrucBanScreen extends StatefulWidget {
  final PhanCongTrucBan? phanCong;
  final List<Truong> danhSachTruong;

  const AddEditPhanCongTrucBanScreen({
    Key? key,
    this.phanCong,
    required this.danhSachTruong,
  }) : super(key: key);

  @override
  State<AddEditPhanCongTrucBanScreen> createState() =>
      _AddEditPhanCongTrucBanScreenState();
}

class _AddEditPhanCongTrucBanScreenState extends State<AddEditPhanCongTrucBanScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  String? _selectedTruongId;
  String? _selectedGiaoVienId;
  List<DateTime> _selectedDates = [];
  List<GiaoVien> _danhSachGiaoVien = [];

  final TextEditingController _ghiChuController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();

    if (widget.phanCong != null) {
      _selectedTruongId = widget.phanCong!.idTruong;
      _selectedGiaoVienId = widget.phanCong!.idGiaoVien;
      _selectedDates = List.from(widget.phanCong!.ngayTrucBan);
      _ghiChuController.text = widget.phanCong!.ghiChu ?? '';
    }

    _loadGiaoVien();
  }

  Future<void> _loadGiaoVien() async {
    setState(() => _isLoading = true);

    try {
      final danhSachGiaoVien = await GiaoVienService.getAllGiaoVien();

      setState(() {
        _danhSachGiaoVien = danhSachGiaoVien;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Đã xảy ra lỗi khi tải danh sách giáo viên: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final initialDate = DateTime.now();
    final firstDate = DateTime(initialDate.year - 1);
    final lastDate = DateTime(initialDate.year + 1);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      // Check if date is already selected
      final alreadySelected = _selectedDates.any((date) =>
      date.year == pickedDate.year &&
          date.month == pickedDate.month &&
          date.day == pickedDate.day);

      if (!alreadySelected) {
        setState(() {
          _selectedDates.add(pickedDate);
          _selectedDates.sort((a, b) => a.compareTo(b));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ngày này đã được chọn')),
        );
      }
    }
  }

  void _removeDate(int index) {
    setState(() {
      _selectedDates.removeAt(index);
    });
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDates.isEmpty) {
      _showErrorDialog('Vui lòng chọn ít nhất một ngày trực ban');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      final PhanCongTrucBan phanCongTrucBan = widget.phanCong != null
          ? widget.phanCong!.copyWith(
        idTruong: _selectedTruongId,
        idGiaoVien: _selectedGiaoVienId,
        ngayTrucBan: _selectedDates,
        ghiChu: _ghiChuController.text.trim(),
      )
          : PhanCongTrucBan(
        idTruong: _selectedTruongId!,
        idGiaoVien: _selectedGiaoVienId!,
        ngayTrucBan: _selectedDates,
        ghiChu: _ghiChuController.text.trim().isEmpty
            ? null
            : _ghiChuController.text.trim(),
        createdAt: now,
      );

      if (widget.phanCong == null) {
        await PhanCongTrucBanService.create(phanCongTrucBan);
      } else {
        await PhanCongTrucBanService.update(phanCongTrucBan);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.phanCong == null
                  ? 'Đã thêm phân công trực ban mới'
                  : 'Đã cập nhật phân công trực ban',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _ghiChuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.phanCong == null
            ? 'Thêm phân công trực ban'
            : 'Chỉnh sửa phân công trực ban'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // School dropdown
            DropdownButtonFormField<String>(
              value: _selectedTruongId,
              decoration: const InputDecoration(
                labelText: 'Trường',
                border: OutlineInputBorder(),
              ),
              items: widget.danhSachTruong.map((truong) {
                return DropdownMenuItem<String>(
                  value: truong.id,
                  child: Text(truong.tenTruong),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTruongId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn trường';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Teacher dropdown
            DropdownButtonFormField<String>(
              value: _selectedGiaoVienId,
              decoration: const InputDecoration(
                labelText: 'Giáo viên',
                border: OutlineInputBorder(),
              ),
              items: _danhSachGiaoVien.map((giaoVien) {
                return DropdownMenuItem<String>(
                  value: giaoVien.id,
                  child: Text(giaoVien.hoTen),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGiaoVienId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn giáo viên';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Date selection section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ngày trực ban',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Chọn ngày'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Selected dates
            _selectedDates.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có ngày được chọn',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            )
                : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                _selectedDates.length,
                    (index) => Chip(
                  label: Text(_dateFormat.format(_selectedDates[index])),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeDate(index),
                  backgroundColor: Colors.blue.shade100,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _ghiChuController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saveAssignment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                widget.phanCong == null
                    ? 'Thêm phân công trực ban'
                    : 'Cập nhật phân công',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
