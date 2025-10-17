import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quan_ly_hoc_sinh/models/lop.dart';
import 'package:quan_ly_hoc_sinh/services/local_data_service.dart';

import '../../../models/hoc_sinh.dart';
import '../../../models/user.dart';
import '../../../models/xin_ra_vao.dart';
import '../../../services/hoc_sinh_service.dart';
import '../../../services/user_service.dart';
import '../../../services/xin_ra_vao_service.dart';

class DangKyRaNgoaiScreen extends StatefulWidget {
  const DangKyRaNgoaiScreen({super.key});

  @override
  State<DangKyRaNgoaiScreen> createState() => _DangKyRaNgoaiScreenState();
}

class _DangKyRaNgoaiScreenState extends State<DangKyRaNgoaiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lyDoController = TextEditingController();
  DateTime _thoiGianRa = DateTime.now();
  DateTime _thoiGianVaoDuKien = DateTime.now().add(const Duration(hours: 2));
  HocSinh? hocSinh = null;
  Lop? lop = null;
  LocalDataService localDataService = LocalDataService.instance;

  @override
  void dispose() {
    _lyDoController.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    _fetchHocSinh();
  }

  Future<void> _fetchHocSinh() async {
    if (localDataService.getId() == null) return;
    HocSinh? fetchedHocSinh = await HocSinhService.getHocSinhById(
      localDataService.getId()!,
    );
    debugPrint("Fetched HocSinh: ${fetchedHocSinh?.toFirestore()}");
    setState(() {
      hocSinh = fetchedHocSinh;
    });
  }

  Future<void> _selectTime(bool isTimeOut) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        isTimeOut ? _thoiGianRa : _thoiGianVaoDuKien,
      ),
    );

    if (time != null) {
      setState(() {
        final now = DateTime.now();
        if (isTimeOut) {
          _thoiGianRa = DateTime(
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          );
        } else {
          _thoiGianVaoDuKien = DateTime(
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          );
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        // TODO: Implement submission logic
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đang xử lý yêu cầu...')));
        print("hocSinh: ${hocSinh}");
        if (hocSinh == null) return;

        XinRaVao xinRaVao = XinRaVao(
          idHs: hocSinh!.id!,
          hoTenHs: hocSinh!.hoTen,
          soTheHocSinh: hocSinh!.soTheHocSinh,
          idLop: hocSinh!.idLop,
          lyDo: _lyDoController.text,
          nguon: NguonXin.appHs,
          loai: LoaiXin.xinRa,
          thoiGianXin: _thoiGianRa,
          createdAt: DateTime.now(),
          thoiGianVaoDuKien: _thoiGianVaoDuKien,
        );
        await XinRaVaoService.createXinRaVao(xinRaVao);
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi yêu cầu: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Ra Ngoài'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSection(),
              const SizedBox(height: 20),
              _buildTimeSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleSubmit,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.send),
      ),
    );
  }

    Widget _buildInfoSection() {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin học sinh',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              if (hocSinh != null) ...[
                _buildInfoRow(Icons.person, 'Họ và tên:', hocSinh!.hoTen),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Ngày sinh:',
                  DateFormat('dd/MM/yyyy').format(hocSinh!.ngaySinh),
                ),
                _buildInfoRow(
                  Icons.credit_card,
                  'Số thẻ học sinh:',
                  hocSinh!.soTheHocSinh,
                ),
                _buildInfoRow(
                  Icons.class_,
                  'Lớp:',
                  hocSinh!.idLop ?? 'Chưa có lớp',
                ),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      );
    }

  Widget _buildTimeSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thời gian xin ra vào',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimeRow(
              Icons.exit_to_app,
              'Thời gian xin ra:',
              _formatDateTime(_thoiGianRa),
              () => _selectTime(true),
            ),
            _buildTimeRow(
              Icons.input,
              'Thời gian xin vào:',
              _formatDateTime(_thoiGianVaoDuKien),
              () => _selectTime(false),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lyDoController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Lý do xin ra',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note),
                filled: true,
                fillColor: Colors.blue[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập lý do';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(value),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
  }
}
