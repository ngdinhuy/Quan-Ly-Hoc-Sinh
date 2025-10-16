import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/phu_huynh.dart';
import '../models/hoc_sinh.dart';
import '../services/phu_huynh_service.dart';

class PhuHuynhFormDialog extends StatefulWidget {
  final HocSinh hocSinh;
  final PhuHuynh? phuHuynh;
  final VoidCallback onSaved;

  const PhuHuynhFormDialog({
    super.key,
    required this.hocSinh,
    this.phuHuynh,
    required this.onSaved,
  });

  @override
  State<PhuHuynhFormDialog> createState() => _PhuHuynhFormDialogState();
}

class _PhuHuynhFormDialogState extends State<PhuHuynhFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hoTenController = TextEditingController();
  final _soCccdController = TextEditingController();
  final _soDienThoaiController = TextEditingController();
  final _quanHeController = TextEditingController();
  final _gmailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.phuHuynh != null) {
      _hoTenController.text = widget.phuHuynh!.hoTen;
      _soCccdController.text = widget.phuHuynh!.soCccd;
      _soDienThoaiController.text = widget.phuHuynh!.soDienThoai;
      _quanHeController.text = widget.phuHuynh!.quanHe;
      _gmailController.text = widget.phuHuynh!.gmail;
    }
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _soCccdController.dispose();
    _soDienThoaiController.dispose();
    _quanHeController.dispose();
    _gmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.phuHuynh == null ? 'Thêm Phụ Huynh Mới' : 'Chỉnh Sửa Phụ Huynh',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Học Sinh: ${widget.hocSinh.hoTen} - ${widget.hocSinh.soTheHocSinh}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _soCccdController,
                decoration: const InputDecoration(
                  labelText: 'Số CCCD *',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số CCCD';
                  }
                  if (value.length != 9 && value.length != 12) {
                    return 'Số CCCD phải có 9 hoặc 12 số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _soDienThoaiController,
                decoration: const InputDecoration(
                  labelText: 'Số Điện Thoại *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _gmailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quanHeController,
                decoration: const InputDecoration(
                  labelText: 'Quan Hệ *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập quan hệ';
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
          onPressed: _isLoading ? null : _savePhuHuynh,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(widget.phuHuynh == null ? 'Thêm' : 'Cập Nhật'),
        ),
      ],
    );
  }

  Future<void> _savePhuHuynh() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final phuHuynh = PhuHuynh(
        id: widget.phuHuynh?.id,
        hoTen: _hoTenController.text.trim(),
        soCccd: _soCccdController.text.trim(),
        soDienThoai: _soDienThoaiController.text.trim(),
        quanHe: _quanHeController.text.trim(),
        idHs: widget.hocSinh.id!,
        gmail: _gmailController.text.trim(),
        createdAt: widget.phuHuynh?.createdAt ?? DateTime.now(),
      );

      if (widget.phuHuynh == null) {
        await PhuHuynhService.createPhuHuynh(phuHuynh);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm phụ huynh thành công')),
          );
        }
      } else {
        await PhuHuynhService.updatePhuHuynh(widget.phuHuynh!.id!, phuHuynh);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật phụ huynh thành công')),
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
