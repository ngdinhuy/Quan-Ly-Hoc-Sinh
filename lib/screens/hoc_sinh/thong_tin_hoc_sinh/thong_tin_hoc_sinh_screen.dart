import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/hoc_sinh.dart';
import '../../../services/hoc_sinh_service.dart';

class ThongTinHocSinhScreen extends StatefulWidget {
  final String hocSinhId;

  const ThongTinHocSinhScreen({Key? key, required this.hocSinhId}) : super(key: key);

  @override
  State<ThongTinHocSinhScreen> createState() => _ThongTinHocSinhScreenState();
}

class _ThongTinHocSinhScreenState extends State<ThongTinHocSinhScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  late HocSinh _hocSinh;

  final _hoTenController = TextEditingController();
  final _soDienThoaiController = TextEditingController();
  final _diaChiController = TextEditingController();
  final _matKhauController = TextEditingController();
  final _confirmMatKhauController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHocSinh();
  }

  Future<void> _loadHocSinh() async {
    try {
      final hocSinh = await HocSinhService.getHocSinhById(widget.hocSinhId);
      if (hocSinh != null) {
        setState(() {
          _hocSinh = hocSinh;
          _hoTenController.text = hocSinh.hoTen;
          _soDienThoaiController.text = hocSinh.soDienThoai ?? '';
          _diaChiController.text = hocSinh.diaChi ?? '';
          _matKhauController.text = '';
          _confirmMatKhauController.text = '';
          _isLoading = false;
        });
      } else {
        _showErrorDialog('Không tìm thấy thông tin học sinh');
      }
    } catch (e) {
      _showErrorDialog('Đã xảy ra lỗi khi tải dữ liệu: ${e.toString()}');
    }
  }

  Future<void> _updateHocSinh() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Chỉ cập nhật những thông tin được phép thay đổi
      final updatedHocSinh = _hocSinh.copyWith(
        hoTen: _hoTenController.text.trim(),
        soDienThoai: _soDienThoaiController.text.trim(),
        diaChi: _diaChiController.text.trim(),
        matKhau: _matKhauController.text.isNotEmpty ? _matKhauController.text.trim() : null,
      );

      await HocSinhService.updateHocSinh(_hocSinh.id!, updatedHocSinh);

      // Tải lại thông tin học sinh sau khi cập nhật
      await _loadHocSinh();

      setState(() {
        _isEditing = false;
        _matKhauController.clear();
        _confirmMatKhauController.clear();
      });

      _showSuccessDialog('Cập nhật thông tin thành công');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Đã xảy ra lỗi khi cập nhật: ${e.toString()}');
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thành công'),
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

  @override
  void dispose() {
    _hoTenController.dispose();
    _soDienThoaiController.dispose();
    _diaChiController.dispose();
    _matKhauController.dispose();
    _confirmMatKhauController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  // Reset các giá trị khi hủy chỉnh sửa
                  _hoTenController.text = _hocSinh.hoTen;
                  _soDienThoaiController.text = _hocSinh.soDienThoai ?? '';
                  _diaChiController.text = _hocSinh.diaChi ?? '';
                  _matKhauController.clear();
                  _confirmMatKhauController.clear();
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const CircularProgressIndicator()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _hocSinh.avatarFaceUrl != null
                      ? NetworkImage(_hocSinh.avatarFaceUrl!)
                      : null,
                  child: _hocSinh.avatarFaceUrl == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Thông tin cơ bản - không thể thay đổi
              _buildInfoSection('Thông tin học sinh'),
              _buildInfoField('Mã học sinh:', _hocSinh.soTheHocSinh),
              _buildInfoField('Ngày sinh:', DateFormat('dd/MM/yyyy').format(_hocSinh.ngaySinh)),
              _buildInfoField('Lớp:', _hocSinh.phongSo),

              const SizedBox(height: 16),

              // Thông tin có thể chỉnh sửa
              _buildEditableSection('Thông tin cá nhân'),
              _buildEditableField(
                label: 'Họ và tên',
                controller: _hoTenController,
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  return null;
                },
              ),
              _buildEditableField(
                label: 'Số điện thoại',
                controller: _soDienThoaiController,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              _buildEditableField(
                label: 'Địa chỉ',
                controller: _diaChiController,
                enabled: _isEditing,
                maxLines: 3,
              ),

              if (_isEditing) ...[
                const SizedBox(height: 16),
                _buildEditableSection('Thay đổi mật khẩu (tùy chọn)'),
                _buildEditableField(
                  label: 'Mật khẩu mới',
                  controller: _matKhauController,
                  enabled: _isEditing,
                  obscureText: true,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                _buildEditableField(
                  label: 'Xác nhận mật khẩu',
                  controller: _confirmMatKhauController,
                  enabled: _isEditing,
                  obscureText: true,
                  validator: (value) {
                    if (_matKhauController.text.isNotEmpty && value != _matKhauController.text) {
                      return 'Mật khẩu không khớp';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),

              // Nút cập nhật
              if (_isEditing)
                TextButton(
                  child: Text('Cập nhật thông tin'),
                  onPressed: _updateHocSinh,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
