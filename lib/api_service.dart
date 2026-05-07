import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'http://10.0.2.2:8000/api'; // Assuming emulator, change to real IP if running on device
  static String? _cachedToken;
  static Map<String, dynamic>? _cachedUserData;

  Future<String?> getToken() async {
    // TODO: Replace with shared_preferences after fixing dependencies
    return _cachedToken;
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String userType,
  ) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'user_type': userType,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data.containsKey('access_token')) {
      // TODO: Replace with shared_preferences after fixing dependencies
      _cachedToken = data['access_token'];
      _cachedUserData = data['user'];
      return {'success': true, 'user': data['user']};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String? nim,
    String password,
    String userType,
  ) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'nim': nim,
        'password': password,
        'password_confirmation': password,
        'user_type': userType,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'] ?? 'Registrasi berhasil',
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Registrasi gagal',
      };
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
    // TODO: Replace with shared_preferences after fixing dependencies
    _cachedToken = null;
    _cachedUserData = null;
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

  Future<Map<String, dynamic>> getDosenIzin() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dosen/izin'),
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

  Future<Map<String, dynamic>> setIzinStatus(int izinId, bool approve) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final action = approve ? 'approve' : 'reject';
      final response = await http.post(
        Uri.parse('$baseUrl/dosen/izin/$izinId/$action'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
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

  Future<Map<String, dynamic>> getMahasiswaEnrollments() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mahasiswa/enrollments'),
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

  Future<Map<String, dynamic>> requestEnrollment(int matkulId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mahasiswa/enrollments/$matkulId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Berhasil mengajukan'};
      }
      return {'success': false, 'message': 'Gagal mengajukan'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getDosenEnrollmentRequests() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dosen/enrollments'),
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

  Future<Map<String, dynamic>> setEnrollmentStatus(
    int enrollmentId,
    bool approve,
  ) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final action = approve ? 'approve' : 'reject';
      final response = await http.patch(
        Uri.parse('$baseUrl/dosen/enrollments/$enrollmentId/$action'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Berhasil'};
      }
      return {'success': false, 'message': 'Gagal memperbarui status'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendOtpReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Gagal',
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Gagal',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Generate QR token from backend. [durationMinutes] must be one of 5, 10, 15, or 30.
  Future<Map<String, dynamic>> generateQrCode(
    int matkulId,
    int durationMinutes,
  ) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/dosen/qr-code?matkul_id=$matkulId&duration=$durationMinutes',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'token': data['token'],
          'expiresAt': data['expiresAt'],
          'expiresAtTimestamp': data['expiresAtTimestamp'],
          'matkulId': data['matkulId'],
          'duration': data['duration'],
          'matkuls': data['matkuls'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal generate QR',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
