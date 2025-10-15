import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tham_ph.dart';
import '../models/hoc_sinh.dart';
import '../models/phu_huynh.dart';
import '../services/tham_ph_service.dart';
import '../services/phu_huynh_service.dart';

class ThamPhFormDialog extends StatefulWidget {
  final HocSinh hocSinh;
  final ThamPh? thamPh;
  final VoidCallback onSaved;

  const ThamPhFormDialog({
    super.key,
    required this.hocSinh,
    this.thamPh,
    required this.onSaved,
  });

  @override
  State<ThamPhFormDialog> createState() => _ThamPhFormDialogState();
}

class _ThamPhFormDialogState extends State<ThamPhFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hoTenPhController = TextEditingController();
  final _soCccdController = TextEditingController();
  final _soDienThoaiController = TextEditingController();
  PhuHuynh? _selectedPhuHuynh;
  List<PhuHuynh> _phuHuynhList = [];
  DateTime? _thoiGianDen;
  DateTime? _thoiGianKetThuc;
  TrangThaiTham _trangThai = TrangThaiTham.dangTham;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPhuHuynhList();
    if (widget.thamPh != null) {
      _hoTenPhController.text = widget.thamPh!.hoTenPh;
      _soCccdController.text = widget.thamPh!.soCccd;
      _soDienThoaiController.text = widget.thamPh!.soDienThoai;
      _thoiGianDen = widget.thamPh!.thoiGianDen;
      _thoiGianKetThuc = widget.thamPh!.thoiGianKetThuc;
      _trangThai = widget.thamPh!.trangThai;
    } else {
      _thoiGianDen = DateTime.now();
    }
  }

  @override
  void dispose() {
    _hoTenPhController.dispose();
    _soCccdController.dispose();
    _soDienThoaiController.dispose();
    super.dispose();
  }

  Future<void> _loadPhuHuynhList() async {
    try {
      final phuHuynhList = await PhuHuynhService.getPhuHuynhByHs(
        widget.hocSinh.id!,
      );
      setState(() {
        _phuHuynhList = phuHuynhList;
        if (phuHuynhList.isNotEmpty && _selectedPhuHuynh == null) {
          _selectedPhuHuynh = phuHuynhList.first;
          _hoTenPhController.text = phuHuynhList.first.hoTen;
          _soCccdController.text = phuHuynhList.first.soCccd;
          _soDienThoaiController.text = phuHuynhList.first.soDienThoai;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách phụ huynh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.thamPh == null
            ? 'Thêm Lịch Thăm Con'
            : 'Chỉnh Sửa Lịch Thăm Con',
      ),
      content: SizedBox(
        width: 500,
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
              if (_phuHuynhList.isNotEmpty)
                DropdownButtonFormField<PhuHuynh>(
                  value: _selectedPhuHuynh,
                  decoration: const InputDecoration(
                    labelText: 'Phụ Huynh *',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _phuHuynhList.map((phuHuynh) {
                        return DropdownMenuItem(
                          value: phuHuynh,
                          child: Text('${phuHuynh.hoTen} - ${phuHuynh.quanHe}'),
                        );
                      }).toList(),
                  onChanged: (phuHuynh) {
                    setState(() {
                      _selectedPhuHuynh = phuHuynh;
                      if (phuHuynh != null) {
                        _hoTenPhController.text = phuHuynh.hoTen;
                        _soCccdController.text = phuHuynh.soCccd;
                        _soDienThoaiController.text = phuHuynh.soDienThoai;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Vui lòng chọn phụ huynh';
                    }
                    return null;
                  },
                )
              else
                Column(
                  children: [
                    TextFormField(
                      controller: _hoTenPhController,
                      decoration: const InputDecoration(
                        labelText: 'Họ Tên Phụ Huynh *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ tên phụ huynh';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _soCccdController,
                            decoration: const InputDecoration(
                              labelText: 'Số CCCD *',
                              border: OutlineInputBorder(),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
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
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectThoiGianDen,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Thời Gian Đến *',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _thoiGianDen != null
                              ? _formatDateTime(_thoiGianDen!)
                              : 'Chọn thời gian',
                          style: TextStyle(
                            color:
                                _thoiGianDen != null
                                    ? Colors.black
                                    : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectThoiGianKetThuc,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Thời Gian Kết Thúc',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _thoiGianKetThuc != null
                              ? _formatDateTime(_thoiGianKetThuc!)
                              : 'Chọn thời gian',
                          style: TextStyle(
                            color:
                                _thoiGianKetThuc != null
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
              DropdownButtonFormField<TrangThaiTham>(
                value: _trangThai,
                decoration: const InputDecoration(
                  labelText: 'Trạng Thái *',
                  border: OutlineInputBorder(),
                ),
                items:
                    TrangThaiTham.values.map((trangThai) {
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
          onPressed: _isLoading ? null : _saveThamPh,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(widget.thamPh == null ? 'Thêm' : 'Cập Nhật'),
        ),
      ],
    );
  }

  String _getStatusText(TrangThaiTham trangThai) {
    switch (trangThai) {
      case TrangThaiTham.dangTham:
        return 'Đang thăm';
      case TrangThaiTham.daVe:
        return 'Đã về';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectThoiGianDen() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _thoiGianDen ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_thoiGianDen ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _thoiGianDen = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectThoiGianKetThuc() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _thoiGianKetThuc ?? DateTime.now(),
      firstDate: _thoiGianDen ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_thoiGianKetThuc ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _thoiGianKetThuc = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveThamPh() async {
    if (!_formKey.currentState!.validate()) return;
    if (_thoiGianDen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian đến')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final thamPh = ThamPh(
        id: widget.thamPh?.id,
        idPh: _selectedPhuHuynh?.id ?? '',
        hoTenPh: _hoTenPhController.text.trim(),
        soCccd: _soCccdController.text.trim(),
        soDienThoai: _soDienThoaiController.text.trim(),
        idHs: widget.hocSinh.id!,
        hoTenHs: widget.hocSinh.hoTen,
        phongSo: widget.hocSinh.phongSo,
        thoiGianDen: _thoiGianDen!,
        thoiGianKetThuc: _thoiGianKetThuc,
        trangThai: _trangThai,
        createdAt: widget.thamPh?.createdAt ?? DateTime.now(),
      );

      if (widget.thamPh == null) {
        await ThamPhService.createThamPh(thamPh);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm lịch thăm con thành công')),
          );
        }
      } else {
        await ThamPhService.updateThamPh(widget.thamPh!.id!, thamPh);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật lịch thăm con thành công')),
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
