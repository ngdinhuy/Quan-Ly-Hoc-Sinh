import 'package:flutter/material.dart';
import '../models/truong.dart';
import '../services/truong_service.dart';
import '../widgets/truong_form_dialog.dart';

class TruongScreen extends StatefulWidget {
  const TruongScreen({super.key});

  @override
  State<TruongScreen> createState() => _TruongScreenState();
}

class _TruongScreenState extends State<TruongScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quản Lý Trường Học',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showTruongFormDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Trường'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Truong>>(
              stream: TruongService.streamTruong(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final truongList = snapshot.data ?? [];

                if (truongList.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có trường nào được thêm',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return Card(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Tên Trường')),
                      DataColumn(label: Text('Địa Chỉ')),
                      DataColumn(label: Text('Số Điện Thoại')),
                      DataColumn(label: Text('Mã Trường')),
                      DataColumn(label: Text('Thao Tác')),
                    ],
                    rows:
                        truongList.map((truong) {
                          return DataRow(
                            cells: [
                              DataCell(Text(truong.tenTruong)),
                              DataCell(Text(truong.diaChi)),
                              DataCell(Text(truong.sdt)),
                              DataCell(Text(truong.maTruong)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed:
                                          () => _showTruongFormDialog(
                                            truong: truong,
                                          ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteTruong(truong),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTruongFormDialog({Truong? truong}) {
    showDialog(
      context: context,
      builder: (context) => TruongFormDialog(truong: truong),
    );
  }

  void _deleteTruong(Truong truong) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác Nhận Xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa trường "${truong.tenTruong}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await TruongService.deleteTruong(truong.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Xóa trường thành công')),
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
