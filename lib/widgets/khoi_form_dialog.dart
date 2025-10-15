import 'package:flutter/material.dart';
import '../models/truong.dart';
import '../models/khoi.dart';
import '../services/khoi_service.dart';

class KhoiFormDialog extends StatefulWidget {
  final Truong truong;
  final Khoi? khoi;
  final VoidCallback onSaved;

  const KhoiFormDialog({
    super.key,
    required this.truong,
    this.khoi,
    required this.onSaved,
  });

  @override
  State<KhoiFormDialog> createState() => _KhoiFormDialogState();
}

class _KhoiFormDialogState extends State<KhoiFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tenKhoiController = TextEditingController();
  final _maKhoiController = TextEditingController();
  final _ghiChuController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.khoi != null) {
      _tenKhoiController.text = widget.khoi!.tenKhoi;
      _maKhoiController.text = widget.khoi!.maKhoi;
      _ghiChuController.text = widget.khoi!.ghiChu ?? '';
    }
  }

  @override
  void dispose() {
    _tenKhoiController.dispose();
    _maKhoiController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.khoi == null ? 'Thêm Khối Mới' : 'Chỉnh Sửa Khối'),
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
              TextFormField(
                controller: _tenKhoiController,
                decoration: const InputDecoration(
                  labelText: 'Tên Khối *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên khối';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maKhoiController,
                decoration: const InputDecoration(
                  labelText: 'Mã Khối *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã khối';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ghiChuController,
                decoration: const InputDecoration(
                  labelText: 'Ghi Chú',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
          onPressed: _isLoading ? null : _saveKhoi,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(widget.khoi == null ? 'Thêm' : 'Cập Nhật'),
        ),
      ],
    );
  }

  Future<void> _saveKhoi() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final khoi = Khoi(
        id: widget.khoi?.id,
        idTruong: widget.truong.id!,
        tenKhoi: _tenKhoiController.text.trim(),
        maKhoi: _maKhoiController.text.trim(),
        ghiChu:
            _ghiChuController.text.trim().isEmpty
                ? null
                : _ghiChuController.text.trim(),
        createdAt: widget.khoi?.createdAt ?? DateTime.now(),
      );

      if (widget.khoi == null) {
        await KhoiService.createKhoi(khoi);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Thêm khối thành công')));
        }
      } else {
        await KhoiService.updateKhoi(widget.khoi!.id!, khoi);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật khối thành công')),
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
