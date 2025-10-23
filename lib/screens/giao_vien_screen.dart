import 'package:flutter/material.dart';
import '../models/giao_vien.dart';
import '../services/giao_vien_service.dart';
import '../widgets/giao_vien_form_dialog.dart';

class GiaoVienScreen extends StatefulWidget {
  const GiaoVienScreen({super.key});

  @override
  State<GiaoVienScreen> createState() => _GiaoVienScreenState();
}

class _GiaoVienScreenState extends State<GiaoVienScreen> {
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
                'Quản Lý Giáo Viên',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showGiaoVienFormDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm Giáo Viên'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showImportDialog(),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import Excel'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<GiaoVien>>(
              stream: GiaoVienService.streamGiaoVien(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final giaoVienList = snapshot.data ?? [];

                if (giaoVienList.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có giáo viên nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Họ Tên')),
                        DataColumn(label: Text('Số Điện Thoại')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Chức Vụ')),
                        DataColumn(label: Text('Thao Tác')),
                      ],
                      rows:
                          giaoVienList.map((giaoVien) {
                            return DataRow(
                              cells: [
                                DataCell(Text(giaoVien.hoTen)),
                                DataCell(Text(giaoVien.soDienThoai)),
                                DataCell(Text(giaoVien.email ?? '')),
                                DataCell(Text(giaoVien.chucVu ?? '')),
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
                                            () => _showGiaoVienFormDialog(
                                              giaoVien: giaoVien,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _deleteGiaoVien(giaoVien),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showGiaoVienFormDialog({GiaoVien? giaoVien}) {
    showDialog(
      context: context,
      builder: (context) => GiaoVienFormDialog(giaoVien: giaoVien),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Import Excel'),
            content: const Text(
              'Chức năng import Excel sẽ được phát triển trong phiên bản tiếp theo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  void _deleteGiaoVien(GiaoVien giaoVien) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác Nhận Xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa giáo viên "${giaoVien.hoTen}"?',
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
                    await GiaoVienService.deleteGiaoVien(giaoVien.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Xóa giáo viên thành công'),
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
                },
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
  }
}
