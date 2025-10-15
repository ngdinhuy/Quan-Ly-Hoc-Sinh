import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/truong.dart';
import '../services/truong_service.dart';

class TruongFormDialog extends StatefulWidget {
  final Truong? truong;

  const TruongFormDialog({super.key, this.truong});

  @override
  State<TruongFormDialog> createState() => _TruongFormDialogState();
}

class _TruongFormDialogState extends State<TruongFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tenTruongController = TextEditingController();
  final _diaChiController = TextEditingController();
  final _sdtController = TextEditingController();
  final _maTruongController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.truong != null) {
      _tenTruongController.text = widget.truong!.tenTruong;
      _diaChiController.text = widget.truong!.diaChi;
      _sdtController.text = widget.truong!.sdt;
      _maTruongController.text = widget.truong!.maTruong;
    }
  }

  @override
  void dispose() {
    _tenTruongController.dispose();
    _diaChiController.dispose();
    _sdtController.dispose();
    _maTruongController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.truong == null ? 'Thêm Trường Mới' : 'Chỉnh Sửa Trường',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tenTruongController,
                decoration: const InputDecoration(
                  labelText: 'Tên Trường *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên trường';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diaChiController,
                decoration: const InputDecoration(
                  labelText: 'Địa Chỉ *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sdtController,
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
                controller: _maTruongController,
                decoration: const InputDecoration(
                  labelText: 'Mã Trường *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã trường';
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
          onPressed: _isLoading ? null : _saveTruong,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(widget.truong == null ? 'Thêm' : 'Cập Nhật'),
        ),
      ],
    );
  }

  Future<void> _saveTruong() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final truong = Truong(
        id: widget.truong?.id,
        tenTruong: _tenTruongController.text.trim(),
        diaChi: _diaChiController.text.trim(),
        sdt: _sdtController.text.trim(),
        maTruong: _maTruongController.text.trim(),
        createdAt: widget.truong?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.truong == null) {
        await TruongService.createTruong(truong);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm trường thành công')),
          );
        }
      } else {
        await TruongService.updateTruong(widget.truong!.id!, truong);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật trường thành công')),
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
