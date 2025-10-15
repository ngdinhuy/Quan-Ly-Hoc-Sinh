import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hoc_sinh.dart';
import '../models/truong.dart';
import '../models/lop.dart';
import '../services/hoc_sinh_service.dart';

class HocSinhFormDialog extends StatefulWidget {
  final Truong truong;
  final Lop lop;
  final HocSinh? hocSinh;
  final VoidCallback onSaved;

  const HocSinhFormDialog({
    super.key,
    required this.truong,
    required this.lop,
    this.hocSinh,
    required this.onSaved,
  });

  @override
  State<HocSinhFormDialog> createState() => _HocSinhFormDialogState();
}

class _HocSinhFormDialogState extends State<HocSinhFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hoTenController = TextEditingController();
  final _soTheController = TextEditingController();
  final _soDienThoaiController = TextEditingController();
  final _diaChiController = TextEditingController();
  final _phongSoController = TextEditingController();
  DateTime? _ngaySinh;
  TrangThaiHocSinh _trangThai = TrangThaiHocSinh.dangHoc;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.hocSinh != null) {
      _hoTenController.text = widget.hocSinh!.hoTen;
      _soTheController.text = widget.hocSinh!.soTheHocSinh;
      _soDienThoaiController.text = widget.hocSinh!.soDienThoai ?? '';
      _diaChiController.text = widget.hocSinh!.diaChi ?? '';
      _phongSoController.text = widget.hocSinh!.phongSo;
      _ngaySinh = widget.hocSinh!.ngaySinh;
      _trangThai = widget.hocSinh!.trangThai;
    } else {
      _phongSoController.text = widget.lop.phongSo;
    }
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _soTheController.dispose();
    _soDienThoaiController.dispose();
    _diaChiController.dispose();
    _phongSoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.hocSinh == null ? 'Thêm Học Sinh Mới' : 'Chỉnh Sửa Học Sinh',
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Trường: ${widget.truong.tenTruong} - Lớp: ${widget.lop.tenLop}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
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
                        controller: _soTheController,
                        decoration: const InputDecoration(
                          labelText: 'Số Thẻ Học Sinh *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số thẻ học sinh';
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
                        controller: _soDienThoaiController,
                        decoration: const InputDecoration(
                          labelText: 'Số Điện Thoại',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (value.length < 10) {
                              return 'Số điện thoại phải có ít nhất 10 số';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectNgaySinh,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ngày Sinh *',
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _diaChiController,
                  decoration: const InputDecoration(
                    labelText: 'Địa Chỉ',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phongSoController,
                        decoration: const InputDecoration(
                          labelText: 'Phòng Số *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập phòng số';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<TrangThaiHocSinh>(
                        value: _trangThai,
                        decoration: const InputDecoration(
                          labelText: 'Trạng Thái *',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            TrangThaiHocSinh.values.map((trangThai) {
                              return DropdownMenuItem(
                                value: trangThai,
                                child: Text(_getStatusText(trangThai)),
                              );
                            }).toList(),
                        onChanged: (trangThai) {
                          setState(() {
                            _trangThai = trangThai!;
                          });
                        },
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
          onPressed: _isLoading ? null : _saveHocSinh,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(widget.hocSinh == null ? 'Thêm' : 'Cập Nhật'),
        ),
      ],
    );
  }

  String _getStatusText(TrangThaiHocSinh trangThai) {
    switch (trangThai) {
      case TrangThaiHocSinh.dangHoc:
        return 'Đang học';
      case TrangThaiHocSinh.tamNghi:
        return 'Tạm nghỉ';
      case TrangThaiHocSinh.nghiHoc:
        return 'Nghỉ học';
    }
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

  Future<void> _saveHocSinh() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ngaySinh == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày sinh')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final hocSinh = HocSinh(
        id: widget.hocSinh?.id,
        hoTen: _hoTenController.text.trim(),
        ngaySinh: _ngaySinh!,
        soTheHocSinh: _soTheController.text.trim(),
        soDienThoai:
            _soDienThoaiController.text.trim().isEmpty
                ? null
                : _soDienThoaiController.text.trim(),
        diaChi:
            _diaChiController.text.trim().isEmpty
                ? null
                : _diaChiController.text.trim(),
        idLop: widget.lop.id!,
        phongSo: _phongSoController.text.trim(),
        trangThai: _trangThai,
        createdAt: widget.hocSinh?.createdAt ?? DateTime.now(),
      );

      if (widget.hocSinh == null) {
        await HocSinhService.createHocSinh(hocSinh);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm học sinh thành công')),
          );
        }
      } else {
        await HocSinhService.updateHocSinh(widget.hocSinh!.id!, hocSinh);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật học sinh thành công')),
          );
        }
      }

      widget.onSaved();
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
