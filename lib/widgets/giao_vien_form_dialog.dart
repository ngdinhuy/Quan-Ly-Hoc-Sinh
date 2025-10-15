import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/giao_vien.dart';
import '../services/giao_vien_service.dart';

class GiaoVienFormDialog extends StatefulWidget {
  final GiaoVien? giaoVien;

  const GiaoVienFormDialog({super.key, this.giaoVien});

  @override
  State<GiaoVienFormDialog> createState() => _GiaoVienFormDialogState();
}

class _GiaoVienFormDialogState extends State<GiaoVienFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hoTenController = TextEditingController();
  final _soDienThoaiController = TextEditingController();
  final _emailController = TextEditingController();
  final _cmndCccdController = TextEditingController();
  final _chucVuController = TextEditingController();
  DateTime? _ngaySinh;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.giaoVien != null) {
      _hoTenController.text = widget.giaoVien!.hoTen;
      _soDienThoaiController.text = widget.giaoVien!.soDienThoai;
      _emailController.text = widget.giaoVien!.email ?? '';
      _cmndCccdController.text = widget.giaoVien!.cmndCccd ?? '';
      _chucVuController.text = widget.giaoVien!.chucVu ?? '';
      _ngaySinh = widget.giaoVien!.ngaySinh;
    }
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _soDienThoaiController.dispose();
    _emailController.dispose();
    _cmndCccdController.dispose();
    _chucVuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.giaoVien == null ? 'Thêm Giáo Viên Mới' : 'Chỉnh Sửa Giáo Viên',
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hoTenController,
                        decoration: const InputDecoration(
                          labelText: 'Họ Tên *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập họ tên';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _soDienThoaiController,
                        decoration: const InputDecoration(
                          labelText: 'Số Điện Thoại *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          if (value.length < 10) {
                            return 'Số điện thoại phải có ít nhất 10 số';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Email không hợp lệ';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cmndCccdController,
                        decoration: const InputDecoration(
                          labelText: 'CMND/CCCD',
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (value.length != 9 && value.length != 12) {
                              return 'CMND/CCCD phải có 9 hoặc 12 số';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _chucVuController,
                        decoration: const InputDecoration(
                          labelText: 'Chức Vụ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectNgaySinh,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ngày Sinh',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _ngaySinh != null
                                ? '${_ngaySinh!.day}/${_ngaySinh!.month}/${_ngaySinh!.year}'
                                : 'Chọn ngày sinh',
                            style: TextStyle(
                              color:
                                  _ngaySinh != null
                                      ? Colors.black
                                      : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveGiaoVien,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(widget.giaoVien == null ? 'Thêm' : 'Cập Nhật'),
        ),
      ],
    );
  }

  Future<void> _selectNgaySinh() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _ngaySinh ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _ngaySinh = date;
      });
    }
  }

  Future<void> _saveGiaoVien() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final giaoVien = GiaoVien(
        id: widget.giaoVien?.id,
        hoTen: _hoTenController.text.trim(),
        soDienThoai: _soDienThoaiController.text.trim(),
        email:
            _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
        cmndCccd:
            _cmndCccdController.text.trim().isEmpty
                ? null
                : _cmndCccdController.text.trim(),
        ngaySinh: _ngaySinh,
        chucVu:
            _chucVuController.text.trim().isEmpty
                ? null
                : _chucVuController.text.trim(),
        roles: widget.giaoVien?.roles ?? ['giaovien'],
        createdAt: widget.giaoVien?.createdAt ?? DateTime.now(),
      );

      if (widget.giaoVien == null) {
        await GiaoVienService.createGiaoVien(giaoVien);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm giáo viên thành công')),
          );
        }
      } else {
        await GiaoVienService.updateGiaoVien(widget.giaoVien!.id!, giaoVien);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật giáo viên thành công')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
