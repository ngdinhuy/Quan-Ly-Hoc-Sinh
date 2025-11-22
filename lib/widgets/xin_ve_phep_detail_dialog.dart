import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/xin_ve_phep.dart';

class XinVePhepDetailDialog extends StatelessWidget {
  final XinVePhep xinVePhep;

  const XinVePhepDetailDialog({super.key, required this.xinVePhep});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chi tiết về phép',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStudentInfoSection(),
                    const SizedBox(height: 16),
                    _buildSourceInfoSection(),
                    const SizedBox(height: 16),
                    _buildLeaveDatesSection(),
                    const SizedBox(height: 16),
                    _buildGuardianInfoSection(),
                    const SizedBox(height: 16),
                    if (xinVePhep.danhSachNgayCatCom.isNotEmpty)
                      _buildMealDeductionSection(),
                    if (xinVePhep.danhSachNgayCatCom.isNotEmpty)
                      const SizedBox(height: 16),
                    _buildReasonSection(),
                    const SizedBox(height: 16),
                    _buildApprovalHistorySection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoSection() {
    return _buildSection('Thông tin học sinh', Icons.person, [
      _buildDetailRow('Họ và tên', xinVePhep.hoTenHocSinh),
      _buildDetailRow('Số thẻ', xinVePhep.soTheHocSinh),
      _buildDetailRow('Lớp', xinVePhep.tenLop),
    ]);
  }

  Widget _buildSourceInfoSection() {
    String sourceText;
    switch (xinVePhep.nguon) {
      case NguonVePhep.appPhuHuynh:
        sourceText = xinVePhep.tenPhuHuynh != null
            ? 'Phụ huynh: ${xinVePhep.tenPhuHuynh}'
            : 'Phụ huynh';
        break;
      case NguonVePhep.appHocSinh:
        sourceText = 'Học sinh tự nộp';
        break;
      case NguonVePhep.giaoVienNhap:
        sourceText = 'Giáo viên nhập';
        break;
    }

    return _buildSection('Nguồn yêu cầu', Icons.source, [
      _buildDetailRow('Nộp bởi', sourceText),
      _buildDetailRow(
        'Thời gian tạo',
        DateFormat('HH:mm dd/MM/yyyy').format(xinVePhep.createdAt),
      ),
    ]);
  }

  Widget _buildLeaveDatesSection() {
    return _buildSection('Thời gian về phép', Icons.calendar_today, [
      _buildDetailRow(
        'Thời gian xin về',
        DateFormat('HH:mm dd/MM/yyyy').format(xinVePhep.thoiGianXinVe),
      ),
      if (xinVePhep.thoiGianXuongTruong != null)
        _buildDetailRow(
          'Thời gian xuống trường',
          DateFormat('HH:mm dd/MM/yyyy').format(xinVePhep.thoiGianXuongTruong!),
        )
      else
        _buildDetailRow('Thời gian xuống trường', 'Chưa xác định'),
    ]);
  }

  Widget _buildGuardianInfoSection() {
    return _buildSection('Thông tin người đón', Icons.person_outline, [
      _buildDetailRow('Họ và tên', xinVePhep.tenNguoiDon),
      _buildDetailRow('Số CCCD', xinVePhep.cccdNguoiDon),
      _buildDetailRow('Số điện thoại', xinVePhep.sdtNguoiDon),
    ], highlight: true);
  }

  Widget _buildMealDeductionSection() {
    final dates = xinVePhep.danhSachNgayCatCom;
    return _buildSection('Ngày cắt cơm', Icons.restaurant, [
      _buildDetailRow('Số ngày cắt cơm', '${dates.length} ngày'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: dates.map((date) {
          return Chip(
            label: Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.blue.withAlpha(25),
            padding: const EdgeInsets.all(4),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildReasonSection() {
    return _buildSection('Lý do', Icons.note, [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(xinVePhep.lyDo, style: const TextStyle(fontSize: 14)),
      ),
    ]);
  }

  Widget _buildApprovalHistorySection() {
    return _buildSection('Trạng thái và lịch sử duyệt', Icons.timeline, [
      _buildTimelineItem(
        'Tạo yêu cầu',
        DateFormat('HH:mm dd/MM/yyyy').format(xinVePhep.createdAt),
        Colors.blue,
        true,
      ),
      if (xinVePhep.trangThai == TrangThaiVePhep.choDuyet)
        _buildTimelineItem(
          'Chờ duyệt',
          'Đang chờ giáo viên duyệt',
          Colors.orange,
          false,
        ),
      if (xinVePhep.thoiGianDuyet != null &&
          xinVePhep.trangThai == TrangThaiVePhep.daDuyet)
        _buildTimelineItem(
          'Đã duyệt',
          '${xinVePhep.tenNguoiDuyet ?? 'Giáo viên'} - ${DateFormat('HH:mm dd/MM/yyyy').format(xinVePhep.thoiGianDuyet!)}',
          Colors.green,
          true,
        ),
      if (xinVePhep.trangThai == TrangThaiVePhep.tuChoi)
        _buildTimelineItem(
          'Từ chối',
          xinVePhep.lyDoTuChoi ?? 'Không có lý do',
          Colors.red,
          true,
        ),
      if (xinVePhep.trangThai == TrangThaiVePhep.daVeTruong)
        _buildTimelineItem(
          'Đã về trường',
          xinVePhep.thoiGianXuongTruong != null
              ? DateFormat(
                  'HH:mm dd/MM/yyyy',
                ).format(xinVePhep.thoiGianXuongTruong!)
              : 'Đã về trường',
          Colors.blue,
          true,
        ),
    ]);
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<Widget> children, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.amber.withAlpha(13)
            : Colors.grey.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: highlight ? Border.all(color: Colors.amber, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    Color color,
    bool completed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? color : Colors.grey.withAlpha(51),
              border: Border.all(color: color, width: 2),
            ),
            child: completed
                ? Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: completed ? color : Colors.grey,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: completed ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
