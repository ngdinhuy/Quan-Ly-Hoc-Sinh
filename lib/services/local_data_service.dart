import 'package:quan_ly_hoc_sinh/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataService {

  static final LocalDataService _instance = LocalDataService._internal();
  // Private constructor
  LocalDataService._internal();
  // Public getter for the singleton instance
  static LocalDataService get instance => _instance;

  late final SharedPreferences prefs;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveIdHocSinh(String idHocSinh) async {
    await prefs.setString('id_hoc_sinh', idHocSinh);
  }

  String? getIdHocSinh() {
    return prefs.getString('id_hoc_sinh');
  }

  Future<void> saveIdGiaoVien(String idGiaoVien) async {
    await prefs.setString('id_giao_vien', idGiaoVien);
  }

  String? getIdGiaoVien() {
    return prefs.getString('id_giao_vien');
  }

  Future<void> saveId(String id) async {
    await prefs.setString('id', id);
  }

  String? getId() {
    return prefs.getString('id');
  }

  Future<void> saveRole(UserRole role) async {
    await prefs.setString('role', role.name);
  }

  UserRole? getRole() {
    final roleString = prefs.getString('role');
    if (roleString == null) return null;
    return UserRole.values.firstWhere(
      (role) => role.name == roleString,
      orElse: () => UserRole.hocsinh,
    );
  }
}