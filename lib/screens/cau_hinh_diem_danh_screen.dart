import 'package:flutter/material.dart';
import '../models/lop.dart';
import '../services/lop_service.dart';

class CauHinhDiemDanhScreen extends StatefulWidget {
  const CauHinhDiemDanhScreen({super.key});

  @override
  State<CauHinhDiemDanhScreen> createState() => _CauHinhDiemDanhScreenState();
}

class _CauHinhDiemDanhScreenState extends State<CauHinhDiemDanhScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Lop> _classes = [];
  Lop? _selectedClass;
  bool _isLoading = true;
  bool _isSaving = false;

  // Config for each day (1-7)
  Map<String, CaHocConfig> _config = {};

  final List<String> _dayNames = [
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'CN',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final classes = await LopService.getAllLop();
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách lớp: $e')),
        );
      }
    }
  }

  void _onClassSelected(Lop? lop) {
    setState(() {
      _selectedClass = lop;
      if (lop != null) {
        _config = lop.cauHinhDiemDanh ?? LopService.getDefaultAttendanceConfig();
      } else {
        _config = {};
      }
    });
  }

  Future<void> _saveConfig() async {
    if (_selectedClass == null) return;

    setState(() => _isSaving = true);
    try {
      await LopService.updateAttendanceConfig(_selectedClass!.id!, _config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu cấu hình thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu cấu hình: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _resetToDefault() {
    setState(() {
      _config = LopService.getDefaultAttendanceConfig();
    });
  }

  void _copyFromDay(int fromDay) {
    final currentDay = _tabController.index + 1;
    if (_config.containsKey(fromDay.toString())) {
      setState(() {
        _config[currentDay.toString()] = _config[fromDay.toString()]!;
      });
    }
  }

  void _updateTime(int day, String period, String field, String value) {
    setState(() {
      final dayKey = day.toString();
      final currentConfig = _config[dayKey] ?? CaHocConfig.defaultConfig();

      ThoiGianCa newThoiGian;
      switch (period) {
        case 'sang':
          newThoiGian = field == 'bat_dau'
              ? currentConfig.caSang.copyWith(batDau: value)
              : currentConfig.caSang.copyWith(ketThuc: value);
          _config[dayKey] = currentConfig.copyWith(caSang: newThoiGian);
          break;
        case 'trua':
          newThoiGian = field == 'bat_dau'
              ? currentConfig.caTrua.copyWith(batDau: value)
              : currentConfig.caTrua.copyWith(ketThuc: value);
          _config[dayKey] = currentConfig.copyWith(caTrua: newThoiGian);
          break;
        case 'chieu_toi':
          newThoiGian = field == 'bat_dau'
              ? currentConfig.caChieuToi.copyWith(batDau: value)
              : currentConfig.caChieuToi.copyWith(ketThuc: value);
          _config[dayKey] = currentConfig.copyWith(caChieuToi: newThoiGian);
          break;
      }
    });
  }

  Future<void> _selectTime(int day, String period, String field) async {
    final dayKey = day.toString();
    final currentConfig = _config[dayKey] ?? CaHocConfig.defaultConfig();

    String currentValue;
    switch (period) {
      case 'sang':
        currentValue =
            field == 'bat_dau' ? currentConfig.caSang.batDau : currentConfig.caSang.ketThuc;
        break;
      case 'trua':
        currentValue =
            field == 'bat_dau' ? currentConfig.caTrua.batDau : currentConfig.caTrua.ketThuc;
        break;
      case 'chieu_toi':
        currentValue = field == 'bat_dau'
            ? currentConfig.caChieuToi.batDau
            : currentConfig.caChieuToi.ketThuc;
        break;
      default:
        currentValue = '07:00';
    }

    final parts = currentValue.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _updateTime(day, period, field, timeString);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Text(
                            'Chọn lớp: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButton<Lop>(
                              value: _selectedClass,
                              isExpanded: true,
                              hint: const Text('Chọn lớp'),
                              items: _classes.map((lop) {
                                return DropdownMenuItem(
                                  value: lop,
                                  child: Text(lop.tenLop),
                                );
                              }).toList(),
                              onChanged: _onClassSelected,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _selectedClass == null ? null : _resetToDefault,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Mặc định'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed:
                                _selectedClass == null || _isSaving ? null : _saveConfig,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: const Text('Lưu'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_selectedClass != null) ...[
                    // Day tabs
                    TabBar(
                      controller: _tabController,
                      tabs: _dayNames.map((name) => Tab(text: name)).toList(),
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                    ),
                    const SizedBox(height: 16),

                    // Config form for selected day
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: List.generate(7, (index) {
                          final day = index + 1;
                          return _buildDayConfig(day);
                        }),
                      ),
                    ),
                  ] else
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Vui lòng chọn lớp để cấu hình',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDayConfig(int day) {
    final dayKey = day.toString();
    final config = _config[dayKey] ?? CaHocConfig.defaultConfig();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Copy from another day
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text('Sao chép từ: '),
                  const SizedBox(width: 8),
                  ...List.generate(7, (index) {
                    final fromDay = index + 1;
                    if (fromDay == day) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        onPressed: () => _copyFromDay(fromDay),
                        child: Text(_dayNames[index]),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Morning period
          _buildPeriodCard(
            title: 'Ca Sáng',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            period: 'sang',
            day: day,
            thoiGian: config.caSang,
          ),
          const SizedBox(height: 16),

          // Noon period
          _buildPeriodCard(
            title: 'Ca Trưa',
            icon: Icons.wb_cloudy,
            color: Colors.blue,
            period: 'trua',
            day: day,
            thoiGian: config.caTrua,
          ),
          const SizedBox(height: 16),

          // Evening period
          _buildPeriodCard(
            title: 'Ca Chiều Tối',
            icon: Icons.nights_stay,
            color: Colors.indigo,
            period: 'chieu_toi',
            day: day,
            thoiGian: config.caChieuToi,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard({
    required String title,
    required IconData icon,
    required Color color,
    required String period,
    required int day,
    required ThoiGianCa thoiGian,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    label: 'Bắt đầu',
                    value: thoiGian.batDau,
                    onTap: () => _selectTime(day, period, 'bat_dau'),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeField(
                    label: 'Kết thúc',
                    value: thoiGian.ketThuc,
                    onTap: () => _selectTime(day, period, 'ket_thuc'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
