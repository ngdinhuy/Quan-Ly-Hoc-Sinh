import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quan_ly_hoc_sinh/widgets/them_hoc_sinh_ra_vao_dialog.dart';
import '../../../models/xin_ra_vao.dart';
import '../../../services/xin_ra_vao_service.dart';

class DanhSachRaVaoTheoLopScreen extends StatefulWidget {
  final String idLop;
  final String tenLop;

  const DanhSachRaVaoTheoLopScreen({
    Key? key,
    required String this.idLop,
    required this.tenLop,
  }) : super(key: key);

  @override
  State<DanhSachRaVaoTheoLopScreen> createState() =>
      _DanhSachRaVaoTheoLopScreenState();
}

class _DanhSachRaVaoTheoLopScreenState
    extends State<DanhSachRaVaoTheoLopScreen> {
  late Stream<List<XinRaVao>> _recordsStream;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');
  TrangThaiXin? _selectedStatus;
  LoaiXin? _selectedType;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    _loadRecords();
  }

  void _loadRecords() {
    _recordsStream = XinRaVaoService.streamXinRaVaoByLop(widget.idLop);
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedType = null;
      _selectedDate = null;
    });
    _loadRecords();
  }

  void _applyFilters() async {
    // Create a base query
    Query query = FirebaseFirestore.instance
        .collection('xin_ra_vao')
        .where('id_lop', isEqualTo: widget.idLop);

    // Apply status filter
    if (_selectedStatus != null) {
      String statusStr;
      switch (_selectedStatus) {
        case TrangThaiXin.choDuyet:
          statusStr = 'cho_duyet';
          break;
        case TrangThaiXin.daDuyet:
          statusStr = 'da_duyet';
          break;
        case TrangThaiXin.daVao:
          statusStr = 'da_vao';
          break;
        case TrangThaiXin.tuChoi:
          statusStr = 'tu_choi';
          break;
        default:
          statusStr = 'cho_duyet';
      }
      query = query.where('trang_thai', isEqualTo: statusStr);
    }

    // Apply type filter
    if (_selectedType != null) {
      String typeStr;
      switch (_selectedType) {
        case LoaiXin.xinRa:
          typeStr = 'xin_ra';
          break;
        case LoaiXin.vaoLai:
          typeStr = 'vao_lai';
          break;
        case LoaiXin.tamNghi:
          typeStr = 'tam_nghi';
          break;
        default:
          typeStr = 'xin_ra';
      }
      query = query.where('loai', isEqualTo: typeStr);
    }

    // Apply date filter
    if (_selectedDate != null) {
      // Get start and end of selected date
      final DateTime startOfDay = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      query = query
          .where(
            'thoi_gian_xin',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('thoi_gian_xin', isLessThan: Timestamp.fromDate(endOfDay));
    }

    // Always order by creation time
    query = query.orderBy('created_at', descending: true);

    // Update the stream with filtered query
    setState(() {
      _recordsStream = query.snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => XinRaVao.fromFirestore(doc)).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ra vào lớp ${widget.tenLop}'),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.filter_list),
          //   onPressed: _showFilterDialog,
          // ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<XinRaVao>>(
              stream: _recordsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.no_accounts, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Không có thông tin ra vào',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: records.length,
                  itemBuilder: (context, index) =>
                      _buildRecordCard(records[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewEntry,
        child: const Icon(Icons.add),
        tooltip: 'Thêm thông tin ra vào',
      ),
    );
  }

  Widget _buildFilterChips() {
    List<Widget> chips = [];

    // Only show the filter summary if at least one filter is active
    if (_selectedStatus != null ||
        _selectedType != null ||
        _selectedDate != null) {
      if (_selectedStatus != null) {
        chips.add(
          _buildChip(
            'Trạng thái: ${_getStatusDisplayName(_selectedStatus!)}',
            Icons.check_circle_outline,
            Colors.blue,
          ),
        );
      }

      if (_selectedType != null) {
        chips.add(
          _buildChip(
            'Loại: ${_getTypeDisplayName(_selectedType!)}',
            Icons.category,
            Colors.purple,
          ),
        );
      }

      if (_selectedDate != null) {
        chips.add(
          _buildChip(
            'Ngày: ${_dateFormat.format(_selectedDate!)}',
            Icons.calendar_today,
            Colors.green,
          ),
        );
      }

      chips.add(
        Chip(
          label: const Text('Xóa bộ lọc'),
          avatar: const Icon(Icons.clear, size: 16),
          backgroundColor: Colors.red[50],
          deleteIcon: const Icon(Icons.delete_outline, size: 16),
          onDeleted: _resetFilters,
        ),
      );

      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView(scrollDirection: Axis.horizontal, children: chips),
      );
    }

    // If no filters are active, don't show the chips row
    return const SizedBox.shrink();
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(label),
        backgroundColor: color.withOpacity(0.1),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        TrangThaiXin? tempStatus = _selectedStatus;
        LoaiXin? tempType = _selectedType;
        DateTime? tempDate = _selectedDate;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Lọc thông tin ra vào'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trạng thái:'),
                    DropdownButton<TrangThaiXin>(
                      isExpanded: true,
                      value: tempStatus,
                      hint: const Text('Tất cả'),
                      items: TrangThaiXin.values.map((status) {
                        return DropdownMenuItem<TrangThaiXin>(
                          value: status,
                          child: Text(_getStatusDisplayName(status)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          tempStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Loại xin:'),
                    DropdownButton<LoaiXin>(
                      isExpanded: true,
                      value: tempType,
                      hint: const Text('Tất cả'),
                      items: LoaiXin.values.map((type) {
                        return DropdownMenuItem<LoaiXin>(
                          value: type,
                          child: Text(_getTypeDisplayName(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          tempType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Ngày:'),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tempDate != null
                                ? _dateFormat.format(tempDate!)
                                : 'Tất cả',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: tempDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setState(() {
                                tempDate = date;
                              });
                            }
                          },
                        ),
                        if (tempDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                tempDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    _selectedStatus = tempStatus;
                    _selectedType = tempType;
                    _selectedDate = tempDate;
                    Navigator.of(context).pop();
                    _applyFilters();
                  },
                  child: const Text('Áp dụng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRecordCard(XinRaVao record) {
    final Color statusColor = _getStatusColor(record.trangThai);
    final IconData typeIcon = _getTypeIcon(record.loai);
    final String statusText = _getStatusDisplayName(record.trangThai);
    final String typeText = _getTypeDisplayName(record.loai);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    foregroundColor: statusColor,
                    radius: 20,
                    child: Icon(typeIcon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.hoTenHs,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Mã thẻ: ${record.soTheHocSinh}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.label_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(typeText, style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${_dateFormat.format(record.thoiGianXin)} ${_timeFormat.format(record.thoiGianXin)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.subject, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lý do: ${record.lyDo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Add entry time info if available
              if (record.thoiGianVaoThucTe != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.login, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Đã vào lúc: ${_timeFormat.format(record.thoiGianVaoThucTe!)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              // Show expected entry time for approved requests without actual entry time
              if (record.trangThai == TrangThaiXin.daDuyet &&
                  record.thoiGianVaoThucTe == null &&
                  record.thoiGianVaoDuKien != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Dự kiến vào: ${_timeFormat.format(record.thoiGianVaoDuKien!)}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              if (record.trangThai == TrangThaiXin.choDuyet)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _updateStatus(record, TrangThaiXin.daDuyet),
                        icon: const Icon(Icons.check),
                        label: const Text('Duyệt'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _rejectRequest(record),
                        icon: const Icon(Icons.close),
                        label: const Text('Từ chối'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TrangThaiXin status) {
    switch (status) {
      case TrangThaiXin.choDuyet:
        return Colors.orange;
      case TrangThaiXin.daDuyet:
        return Colors.blue;
      case TrangThaiXin.daVao:
        return Colors.green;
      case TrangThaiXin.tuChoi:
        return Colors.red;
    }
  }

  IconData _getTypeIcon(LoaiXin type) {
    switch (type) {
      case LoaiXin.xinRa:
        return Icons.exit_to_app;
      case LoaiXin.vaoLai:
        return Icons.login;
      case LoaiXin.tamNghi:
        return Icons.sick;
    }
  }

  String _getStatusDisplayName(TrangThaiXin status) {
    switch (status) {
      case TrangThaiXin.choDuyet:
        return 'Chờ duyệt';
      case TrangThaiXin.daDuyet:
        return 'Đã duyệt';
      case TrangThaiXin.daVao:
        return 'Đã vào';
      case TrangThaiXin.tuChoi:
        return 'Từ chối';
    }
  }

  String _getTypeDisplayName(LoaiXin type) {
    switch (type) {
      case LoaiXin.xinRa:
        return 'Xin ra';
      case LoaiXin.vaoLai:
        return 'Vào lại';
      case LoaiXin.tamNghi:
        return 'Tạm nghỉ';
    }
  }

  void _updateStatus(XinRaVao record, TrangThaiXin newStatus) async {
    try {
      final updatedRecord = record.copyWith(
        trangThai: newStatus,
        nguoiDuyet: FirebaseFirestore.instance.collection('giao_vien').doc().id,
      );

      await XinRaVaoService.updateXinRaVao(record.id!, updatedRecord);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật trạng thái thành ${_getStatusDisplayName(newStatus)}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _rejectRequest(XinRaVao record) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final updatedRecord = record.copyWith(
                  trangThai: TrangThaiXin.tuChoi,
                  nguoiDuyet: FirebaseFirestore.instance
                      .collection('giao_vien')
                      .doc()
                      .id,
                  lyDoTuChoi: reasonController.text,
                );

                await XinRaVaoService.updateXinRaVao(record.id!, updatedRecord);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã từ chối yêu cầu')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _addNewEntry() {
    showDialog(
      context: context,
      builder: (context) => ThemHocSinhRaVaoDialog(idLop: widget.idLop),
    );
  }

  void _showRecordDetails(XinRaVao record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chi tiết thông tin ra vào',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              _buildDetailItem('Học sinh', record.hoTenHs),
              _buildDetailItem('Mã thẻ', record.soTheHocSinh),
              _buildDetailItem('Loại', _getTypeDisplayName(record.loai)),
              _buildDetailItem(
                'Trạng thái',
                _getStatusDisplayName(record.trangThai),
              ),
              _buildDetailItem(
                'Thời gian xin',
                '${_dateFormat.format(record.thoiGianXin)} ${_timeFormat.format(record.thoiGianXin)}',
              ),

              // Enhanced display for entry times
              if (record.thoiGianVaoDuKien != null)
                _buildDetailItem(
                  'Thời gian vào dự kiến',
                  '${_dateFormat.format(record.thoiGianVaoDuKien!)} ${_timeFormat.format(record.thoiGianVaoDuKien!)}',
                  iconData: Icons.schedule,
                  iconColor: Colors.blue,
                ),

              if (record.thoiGianVaoThucTe != null)
                _buildDetailItem(
                  'Thời gian vào thực tế',
                  '${_dateFormat.format(record.thoiGianVaoThucTe!)} ${_timeFormat.format(record.thoiGianVaoThucTe!)}',
                  iconData: Icons.login,
                  iconColor: Colors.green,
                  textColor: Colors.green,
                ),

              _buildDetailItem('Lý do', record.lyDo),

              if (record.nguoiDuyet != null)
                _buildDetailItem('Người duyệt', record.nguoiDuyet!),

              if (record.lyDoTuChoi != null)
                _buildDetailItem(
                  'Lý do từ chối',
                  record.lyDoTuChoi!,
                  textColor: Colors.red,
                ),

              _buildDetailItem('Nguồn', _getSourceDisplayName(record.nguon)),

              const SizedBox(height: 16),

              if (record.trangThai == TrangThaiXin.daDuyet &&
                  record.thoiGianVaoThucTe == null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _updateStatus(record, TrangThaiXin.daVao),
                    child: const Text('Xác nhận đã vào'),
                  ),
                ),

              if (record.trangThai == TrangThaiXin.choDuyet)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () =>
                            _updateStatus(record, TrangThaiXin.daDuyet),
                        child: const Text('Duyệt'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _rejectRequest(record),
                        child: const Text('Từ chối'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    IconData? iconData,
    Color? iconColor,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (iconData != null) ...[
                  Icon(iconData, size: 16, color: iconColor ?? Colors.grey),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(value, style: TextStyle(color: textColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSourceDisplayName(NguonXin nguon) {
    switch (nguon) {
      case NguonXin.appPh:
        return 'App phụ huynh';
      case NguonXin.appHs:
        return 'App học sinh';
      case NguonXin.gvNhap:
        return 'Giáo viên nhập';
    }
  }
}
