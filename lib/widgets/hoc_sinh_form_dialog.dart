import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quan_ly_hoc_sinh/services/image_service.dart';
import 'package:quan_ly_hoc_sinh/utils/StringExt.dart';
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
  Uint8List? _selectedImage;
  String? _imageUrl;

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
      setState(() {
        _imageUrl = widget.hocSinh!.anhTheUrl;
      });
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
                _buildNhapAnhTheWidget(),
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

  Widget _buildNhapAnhTheWidget() {
    return Container(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload ảnh thẻ học sinh để nhập thông tin tự động',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ConstrainedBox(
                      constraints: new BoxConstraints(minWidth: 160),
                      child:
                          _selectedImage != null
                              ? Image.memory(_selectedImage!, fit: BoxFit.cover)
                              : _imageUrl != null
                              ? Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint(error.toString());
                                  return const Center(
                                    child: Icon(Icons.error_outline),
                                  );
                                },
                              )
                              : const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Chọn ảnh'),
                      ),
                      if (_selectedImage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: _extractInfoFromImage,
                            icon: const Icon(Icons.text_snippet),
                            label: const Text('Nhận dạng thông tin'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      if (_selectedImage != null || _imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                                _imageUrl = null;
                              });
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Xóa ảnh',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();

      // Hiển thị dialog để chọn nguồn ảnh
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Chọn nguồn ảnh'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Chụp ảnh'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Chọn từ thư viện'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ),
      );

      if (source == null) return;

      final picked = await picker.pickImage(source: source);
      if (picked == null) return;

      final Uint8List? bytesFromPicker = await picked.readAsBytes();
      if (bytesFromPicker != null) {
        setState(() {
          _selectedImage = bytesFromPicker;
          _imageUrl = null;
        });
      }
      // Không gọi OCR ở đây, chỉ khi user nhấn nút riêng
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
    }
  }

  /// Extract information from image using OCR
  Future<void> _extractInfoFromImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await uploadImage(_selectedImage!);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi xử lý ảnh: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
        // Thêm học sinh mới
        if (_selectedImage != null) {
          // Upload ảnh mới lên Firebase Storage
          String? url = await ImageService.uploadImageToStorage(
            _selectedImage!,
          );
          hocSinh.anhTheUrl = url;
        }
        await HocSinhService.createHocSinh(hocSinh);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm học sinh thành công')),
          );
        }
      } else {
        // Cập nhật học sinh
        if (_selectedImage != null) {
          // Có ảnh mới được chọn
          if (widget.hocSinh!.anhTheUrl != null) {
            // Xóa ảnh cũ khỏi Firebase Storage
            await ImageService.deleteImageFromStorage(
              widget.hocSinh!.anhTheUrl!,
            );
          }
          // Upload ảnh mới lên Firebase Storage
          String? url = await ImageService.uploadImageToStorage(
            _selectedImage!,
          );
          hocSinh.anhTheUrl = url;
        } else if (_imageUrl != null) {
          // Giữ nguyên ảnh cũ nếu không chọn ảnh mới
          hocSinh.anhTheUrl = widget.hocSinh!.anhTheUrl;
        } else {
          // Xóa ảnh nếu user đã xóa ảnh
          if (widget.hocSinh!.anhTheUrl != null) {
            await ImageService.deleteImageFromStorage(
              widget.hocSinh!.anhTheUrl!,
            );
          }
          hocSinh.anhTheUrl = null;
        }
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

  Future<void> uploadImage(Uint8List image) async {
    final response = await ImageService.sendImageForOCR(imageSource: image);
    if (response['success'] == true) {
      final data = response['student_info'];
      setState(() {
        _hoTenController.text =
            data['full_name'].toString().decodeUnicodeEscapes();
        _soTheController.text = data['student_id'] ?? '';
        if (data['birth_date'] != null) {
          try {
            final parts = data['birth_date'].split('/');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              _ngaySinh = DateTime(year, month, day);
            }
          } catch (e) {
            // Ignore parsing errors
            debugPrint(e.toString());
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã nhập thông tin từ ảnh thẻ')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xử lý ảnh: ${response['message']}')),
      );
    }
  }
}
