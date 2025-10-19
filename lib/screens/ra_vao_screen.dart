import 'package:flutter/material.dart';
import '../models/xin_ra_vao.dart';
import '../models/lop.dart';
import '../services/xin_ra_vao_service.dart';
import '../services/lop_service.dart';
import '../widgets/xin_ra_vao_form_dialog.dart';

class RaVaoScreen extends StatefulWidget {
  const RaVaoScreen({super.key});

  @override
  State<RaVaoScreen> createState() => _RaVaoScreenState();
}

class _RaVaoScreenState extends State<RaVaoScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<XinRaVao> _xinRaVaoList = [];
  List<Lop> _lopList = [];
  Lop? _lop;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lopList = await LopService.getAllLop(); // Load all classes
      setState(() {
        _lopList = lopList;
      });

      if (lopList.isNotEmpty) {
        await _loadXinRaVaoByLop(lopList.first.id!);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadXinRaVaoByLop(String idLop) async {
    try {
      final xinRaVaoList = await XinRaVaoService.getXinRaVaoByLop(idLop);
      setState(() {
        _xinRaVaoList = xinRaVaoList;
      });
    } catch (e) {
      debugPrint("huynd $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách xin ra vào: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản Lý Ra Vào Trường',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_lopList.isNotEmpty)
                DropdownButton<Lop>(
                  value: _lop ?? (_lopList.isNotEmpty ? _lopList.first : null),
                  hint: const Text('Chọn lớp'),
                  items:
                      _lopList.map((lop) {
                        return DropdownMenuItem(
                          value: lop,
                          child: Text(lop.tenLop),
                        );
                      }).toList(),
                  onChanged: (lop) {
                    setState(() {
                      _lop = lop;
                    });
                    if (lop != null) {
                      _loadXinRaVaoByLop(lop.id!);
                    }
                  },
                ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed:
                    _lopList.isNotEmpty
                        ? () => _showXinRaVaoFormDialog()
                        : null,
                icon: const Icon(Icons.add),
                label: const Text('Thêm Yêu Cầu'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Chờ Duyệt', icon: Icon(Icons.pending)),
                    Tab(text: 'Đã Duyệt', icon: Icon(Icons.check)),
                    Tab(text: 'Từ Chối', icon: Icon(Icons.cancel)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildXinRaVaoList(TrangThaiXin.choDuyet),
                      _buildXinRaVaoList(TrangThaiXin.daDuyet),
                      _buildXinRaVaoList(TrangThaiXin.tuChoi),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXinRaVaoList(TrangThaiXin trangThai) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredList =
        _xinRaVaoList.where((xin) => xin.trangThai == trangThai).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          'Không có yêu cầu nào',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return Card(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Học Sinh')),
          DataColumn(label: Text('Số Thẻ')),
          DataColumn(label: Text('Lý Do')),
          DataColumn(label: Text('Thời Gian Xin')),
          DataColumn(label: Text('Nguồn')),
          DataColumn(label: Text('Thao Tác')),
        ],
        rows:
            filteredList.map((xin) {
              return DataRow(
                cells: [
                  DataCell(Text(xin.hoTenHs)),
                  DataCell(Text(xin.soTheHocSinh)),
                  DataCell(Text(xin.lyDo)),
                  DataCell(Text(_formatDateTime(xin.thoiGianXin))),
                  DataCell(Text(_getNguonText(xin.nguon))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (trangThai == TrangThaiXin.choDuyet) ...[
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _duyetXinRaVao(xin, true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _duyetXinRaVao(xin, false),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed:
                              () => _showXinRaVaoFormDialog(xinRaVao: xin),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteXinRaVao(xin),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getNguonText(NguonXin nguon) {
    switch (nguon) {
      case NguonXin.appPh:
        return 'App PH';
      case NguonXin.appHs:
        return 'App HS';
      case NguonXin.gvNhap:
        return 'GV Nhập';
    }
  }

  void _showXinRaVaoFormDialog({XinRaVao? xinRaVao}) {
    if (_lopList.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (context) => XinRaVaoFormDialog(
            lop: _lop ?? _lopList.first,
            xinRaVao: xinRaVao,
            onSaved: () {
              _loadXinRaVaoByLop(_lop?.id ?? _lopList.first.id!);
            },
          ),
    );
  }

  void _duyetXinRaVao(XinRaVao xinRaVao, bool duyet) async {
    try {
      final updatedXinRaVao = xinRaVao.copyWith(
        trangThai: duyet ? TrangThaiXin.daDuyet : TrangThaiXin.tuChoi,
        nguoiDuyet: 'admin', // TODO: Get current user
        lyDoTuChoi: duyet ? null : 'Không đúng quy định',
      );

      await XinRaVaoService.updateXinRaVao(xinRaVao.id!, updatedXinRaVao);
      _loadXinRaVaoByLop(_lop?.id ?? _lopList.first.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(duyet ? 'Duyệt thành công' : 'Từ chối thành công'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _deleteXinRaVao(XinRaVao xinRaVao) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác Nhận Xóa'),
            content: Text('Bạn có chắc chắn muốn xóa yêu cầu này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await XinRaVaoService.deleteXinRaVao(xinRaVao.id!);
                    _loadXinRaVaoByLop(_lop?.id ?? _lopList.first.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Xóa yêu cầu thành công')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  }
                },
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
  }
}
