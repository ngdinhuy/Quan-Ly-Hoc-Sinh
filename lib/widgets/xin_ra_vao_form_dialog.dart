import 'package:flutter/material.dart';
import '../models/xin_ra_vao.dart';
import '../models/lop.dart';
import '../models/hoc_sinh.dart';
import '../services/xin_ra_vao_service.dart';
import '../services/hoc_sinh_service.dart';

class XinRaVaoFormDialog extends StatefulWidget {
  final Lop lop;
  final XinRaVao? xinRaVao;
  final VoidCallback onSaved;

  const XinRaVaoFormDialog({
    super.key,
    required this.lop,
    this.xinRaVao,
    required this.onSaved,
  });

  @override
  State<XinRaVaoFormDialog> createState() => _XinRaVaoFormDialogState();
}

class _XinRaVaoFormDialogState extends State<XinRaVaoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _lyDoController = TextEditingController();
  HocSinh? _selectedHocSinh;
  List<HocSinh> _hocSinhList = [];
  LoaiXin _loai = LoaiXin.xinRa;
  DateTime? _thoiGianXin;
  DateTime? _thoiGianVaoDuKien;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHocSinhList();
    if (widget.xinRaVao != null) {
      _lyDoController.text = widget.xinRaVao!.lyDo;
      _loai = widget.xinRaVao!.loai;
      _thoiGianXin = widget.xinRaVao!.thoiGianXin;
      _thoiGianVaoDuKien = widget.xinRaVao!.thoiGianVaoDuKien;
    } else {
      _thoiGianXin = DateTime.now();
    }
  }

  @override
  void dispose() {
    _lyDoController.dispose();
    super.dispose();
  }

  Future<void> _loadHocSinhList() async {
    try {
      final hocSinhList = await HocSinhService.getHocSinhByLop(widget.lop.id!);
      setState(() {
        _hocSinhList = hocSinhList;
        if (hocSinhList.isNotEmpty && _selectedHocSinh == null) {
          _selectedHocSinh = hocSinhList.first;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách học sinh: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.xinRaVao == null ? 'Thêm Yêu Cầu Mới' : 'Chỉnh Sửa Yêu Cầu',
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lớp: ${widget.lop.tenLop}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HocSinh>(
                value: _selectedHocSinh,
                decoration: const InputDecoration(
                  labelText: 'Học Sinh *',
                  border: OutlineInputBorder(),
                ),
                items:
                    _hocSinhList.map((hocSinh) {
                      return DropdownMenuItem(
                        value: hocSinh,
                        child: Text(
                          '${hocSinh.hoTen} - ${hocSinh.soTheHocSinh}',
                        ),
                      );
                    }).toList(),
                onChanged: (hocSinh) {
                  setState(() {
                    _selectedHocSinh = hocSinh;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn học sinh';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LoaiXin>(
                value: _loai,
                decoration: const InputDecoration(
                  labelText: 'Loại Yêu Cầu *',
                  border: OutlineInputBorder(),
                ),
                items:
                    LoaiXin.values.map((loai) {
                      return DropdownMenuItem(
                        value: loai,
                        child: Text(_getLoaiText(loai)),
                      );
                    }).toList(),
                onChanged: (loai) {
                  setState(() {
                    _loai = loai!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lyDoController,
                decoration: const InputDecoration(
                  labelText: 'Lý Do *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập lý do';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectThoiGianXin,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Thời Gian Xin *',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _thoiGianXin != null
                              ? _formatDateTime(_thoiGianXin!)
                              : 'Chọn thời gian',
                          style: TextStyle(
                            color:
                                _thoiGianXin != null
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
                      onTap: _selectThoiGianVaoDuKien,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Thời Gian Vào Dự Kiến',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _thoiGianVaoDuKien != null
                              ? _formatDateTime(_thoiGianVaoDuKien!)
                              : 'Chọn thời gian',
                          style: TextStyle(
                            color:
                                _thoiGianVaoDuKien != null
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
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveXinRaVao,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(widget.xinRaVao == null ? 'Thêm' : 'Cập Nhật'),
        ),
      ],
    );
  }

  String _getLoaiText(LoaiXin loai) {
    switch (loai) {
      case LoaiXin.xinRa:
        return 'Xin ra ngoài';
      case LoaiXin.vaoLai:
        return 'Vào lại trường';
      case LoaiXin.tamNghi:
        return 'Tạm nghỉ';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectThoiGianXin() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _thoiGianXin ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_thoiGianXin ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _thoiGianXin = DateTime(
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

  Future<void> _selectThoiGianVaoDuKien() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _thoiGianVaoDuKien ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _thoiGianVaoDuKien ?? DateTime.now(),
        ),
      );
      if (time != null) {
        setState(() {
          _thoiGianVaoDuKien = DateTime(
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

  Future<void> _saveXinRaVao() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHocSinh == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn học sinh')));
      return;
    }
    if (_thoiGianXin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian xin')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final xinRaVao = XinRaVao(
        id: widget.xinRaVao?.id,
        idHs: _selectedHocSinh!.id!,
        hoTenHs: _selectedHocSinh!.hoTen,
        soTheHocSinh: _selectedHocSinh!.soTheHocSinh,
        idLop: widget.lop.id!,
        lyDo: _lyDoController.text.trim(),
        nguon: NguonXin.gvNhap,
        loai: _loai,
        thoiGianXin: _thoiGianXin!,
        thoiGianVaoDuKien: _thoiGianVaoDuKien,
        trangThai: widget.xinRaVao?.trangThai ?? TrangThaiXin.choDuyet,
        createdAt: widget.xinRaVao?.createdAt ?? DateTime.now(),
      );

      if (widget.xinRaVao == null) {
        await XinRaVaoService.createXinRaVao(xinRaVao);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm yêu cầu thành công')),
          );
        }
      } else {
        await XinRaVaoService.updateXinRaVao(widget.xinRaVao!.id!, xinRaVao);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật yêu cầu thành công')),
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
