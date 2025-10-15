import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/truong.dart';
import '../models/khoi.dart';
import '../models/lop.dart';
import '../services/lop_service.dart';

class LopFormDialog extends StatefulWidget {
  final Truong truong;
  final List<Khoi> khoiList;
  final Lop? lop;
  final VoidCallback onSaved;

  const LopFormDialog({
    super.key,
    required this.truong,
    required this.khoiList,
    this.lop,
    required this.onSaved,
  });

  @override
  State<LopFormDialog> createState() => _LopFormDialogState();
}

class _LopFormDialogState extends State<LopFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tenLopController = TextEditingController();
  final _maLopController = TextEditingController();
  final _siSoController = TextEditingController();
  final _phongSoController = TextEditingController();
  Khoi? _selectedKhoi;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.lop != null) {
      _tenLopController.text = widget.lop!.tenLop;
      _maLopController.text = widget.lop!.maLop;
      _siSoController.text = widget.lop!.siSo.toString();
      _phongSoController.text = widget.lop!.phongSo;
      _selectedKhoi = widget.khoiList.firstWhere(
        (khoi) => khoi.id == widget.lop!.idKhoi,
        orElse: () => widget.khoiList.first,
      );
    } else if (widget.khoiList.isNotEmpty) {
      _selectedKhoi = widget.khoiList.first;
    }
  }

  @override
  void dispose() {
    _tenLopController.dispose();
    _maLopController.dispose();
    _siSoController.dispose();
    _phongSoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.lop == null ? 'Thêm Lớp Mới' : 'Chỉnh Sửa Lớp'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trường: ${widget.truong.tenTruong}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Khoi>(
                value: _selectedKhoi,
                decoration: const InputDecoration(
                  labelText: 'Khối *',
                  border: OutlineInputBorder(),
                ),
                items:
                    widget.khoiList.map((khoi) {
                      return DropdownMenuItem(
                        value: khoi,
                        child: Text(khoi.tenKhoi),
                      );
                    }).toList(),
                onChanged: (khoi) {
                  setState(() {
                    _selectedKhoi = khoi;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn khối';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tenLopController,
                decoration: const InputDecoration(
                  labelText: 'Tên Lớp *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên lớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maLopController,
                decoration: const InputDecoration(
                  labelText: 'Mã Lớp *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã lớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _siSoController,
                decoration: const InputDecoration(
                  labelText: 'Sĩ Số *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập sĩ số';
                  }
                  final siSo = int.tryParse(value);
                  if (siSo == null || siSo <= 0) {
                    return 'Sĩ số phải là số dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveLop,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(widget.lop == null ? 'Thêm' : 'Cập Nhật'),
        ),
      ],
    );
  }

  Future<void> _saveLop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final lop = Lop(
        id: widget.lop?.id,
        idTruong: widget.truong.id!,
        idKhoi: _selectedKhoi!.id!,
        tenLop: _tenLopController.text.trim(),
        maLop: _maLopController.text.trim(),
        siSo: int.parse(_siSoController.text),
        phongSo: _phongSoController.text.trim(),
        createdAt: widget.lop?.createdAt ?? DateTime.now(),
      );

      if (widget.lop == null) {
        await LopService.createLop(lop);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Thêm lớp thành công')));
        }
      } else {
        await LopService.updateLop(widget.lop!.id!, lop);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật lớp thành công')),
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
