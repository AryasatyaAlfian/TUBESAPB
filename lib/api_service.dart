import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Assuming emulator, change to real IP if running on device

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> login(String email, String password, String userType) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'user_type': userType,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data.containsKey('access_token')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['access_token']);
      await prefs.setString('user_data', jsonEncode(data['user']));
      return {'success': true, 'user': data['user']};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    }
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<Map<String, dynamic>> getMahasiswaDashboard() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mahasiswa/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Gagal mengambil data'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getDosenDashboard() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dosen/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Gagal mengambil data'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> scanQr(String qrToken) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mahasiswa/scan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'token': qrToken}),
      );
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Berhasil'};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal scan QR'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMahasiswaIzin() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mahasiswa/izin'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Gagal mengambil data'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getDosenIzin() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dosen/izin'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Gagal mengambil data'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> setIzinStatus(int izinId, bool approve) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final action = approve ? 'approve' : 'reject';
      final response = await http.post(
        Uri.parse('$baseUrl/dosen/izin/$izinId/$action'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Berhasil'};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
