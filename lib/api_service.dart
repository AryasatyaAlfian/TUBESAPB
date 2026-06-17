import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config/environment_config.dart';

class ApiService {
  static final String baseUrl = EnvironmentConfig.baseUrl;

  /// Hard cap on every network request so the UI can never spin forever when
  /// the server is slow or unreachable — a TimeoutException surfaces as a
  /// friendly, retry-able error instead of an endless loading indicator.
  static const Duration _timeout = Duration(seconds: 30);

  /// Maps low-level network failures to a short, human-readable Indonesian
  /// message instead of leaking a raw exception string into the UI.
  String _networkError(Object e) {
    if (e is TimeoutException) {
      return 'Server tidak merespons. Periksa koneksi lalu coba lagi.';
    }
    if (e is SocketException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    return 'Terjadi kesalahan jaringan. Silakan coba lagi.';
  }

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<Map<String, dynamic>?> getSavedUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistSession(String token, dynamic user) async {
    await _storage.write(key: _tokenKey, value: token);
    if (user != null) {
      await _storage.write(key: _userKey, value: jsonEncode(user));
    }
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Map<String, String> _authHeaders(String token, {bool json = false}) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json',
  };

  /// Extract a human-readable message from a Laravel JSON response,
  /// including the first validation error when present.
  String _messageFrom(dynamic data, [String fallback = 'Terjadi kesalahan']) {
    if (data is Map) {
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'];
      }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
      if (data['error'] is String) return data['error'];
    }
    return fallback;
  }

  // ── Auth ──────────────────────────────────────────────

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String userType,
  ) async {
    final url = Uri.parse('$baseUrl/login');
    try {
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
      ).timeout(_timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          data is Map &&
          data.containsKey('access_token')) {
        await _persistSession(data['access_token'], data['user']);
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'message': _messageFrom(data, 'Login gagal')};
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String? nim,
    String? jurusan,
    String? angkatan,
    String password,
    String userType,
  ) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'user_type': userType,
    };
    if (nim != null && nim.isNotEmpty) body['nim'] = nim;
    if (jurusan != null && jurusan.isNotEmpty) body['jurusan'] = jurusan;
    if (angkatan != null && angkatan.isNotEmpty) body['angkatan'] = angkatan;

    final url = Uri.parse('$baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(_timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': _messageFrom(data, 'Registrasi berhasil'),
        };
      }
      return {
        'success': false,
        'message': _messageFrom(data, 'Registrasi gagal'),
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await http
            .post(
              Uri.parse('$baseUrl/logout'),
              headers: _authHeaders(token),
            )
            .timeout(_timeout);
      } catch (_) {
        // ignore network errors on logout; clear local session regardless
      }
    }
    await _clearSession();
  }

  // ── Dashboards ────────────────────────────────────────

  Future<Map<String, dynamic>> getMahasiswaDashboard() =>
      _get('/mahasiswa/dashboard');

  Future<Map<String, dynamic>> getDosenDashboard() => _get('/dosen/dashboard');

  Future<Map<String, dynamic>> _get(String path) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$path'), headers: _authHeaders(token))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'message': _messageFrom(
          _tryDecode(response.body),
          'Gagal mengambil data',
        ),
      };
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // ── QR / Scan ─────────────────────────────────────────

  Future<Map<String, dynamic>> scanQr(String qrToken) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mahasiswa/scan'),
        headers: _authHeaders(token, json: true),
        body: jsonEncode({'token': qrToken}),
      ).timeout(_timeout);

      final data = _tryDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': _messageFrom(data, 'Presensi berhasil'),
        };
      }
      return {'success': false, 'message': _messageFrom(data, 'Gagal scan QR')};
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

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
        headers: _authHeaders(token),
      ).timeout(_timeout);
      final data = _tryDecode(response.body);
      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true) {
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
        'message': _messageFrom(data, 'Gagal generate QR'),
      };
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  // ── Izin ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getMahasiswaIzin() => _get('/mahasiswa/izin');

  Future<Map<String, dynamic>> submitIzin({
    required int matkulId,
    required String tanggal,
    String? alasan,
    required File buktiFile,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/mahasiswa/izin'),
      );
      request.headers.addAll(_authHeaders(token));
      request.fields['matkul_id'] = matkulId.toString();
      request.fields['tanggal'] = tanggal;
      if (alasan != null && alasan.isNotEmpty) {
        request.fields['alasan'] = alasan;
      }
      request.files.add(
        await http.MultipartFile.fromPath('bukti_file', buktiFile.path),
      );

      // File upload may legitimately take longer than a plain request.
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      final data = _tryDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': _messageFrom(data, 'Izin berhasil diajukan'),
        };
      }
      return {
        'success': false,
        'message': _messageFrom(data, 'Gagal mengajukan izin'),
      };
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  Future<Map<String, dynamic>> getDosenIzin() => _get('/dosen/izin');

  Future<Map<String, dynamic>> setIzinStatus(int izinId, bool approve) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final action = approve ? 'approve' : 'reject';
      final response = await http.post(
        Uri.parse('$baseUrl/dosen/izin/$izinId/$action'),
        headers: _authHeaders(token),
      ).timeout(_timeout);
      final data = _tryDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': _messageFrom(data, 'Berhasil')};
      }
      return {'success': false, 'message': _messageFrom(data, 'Gagal')};
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  // ── Enrollment ────────────────────────────────────────

  Future<Map<String, dynamic>> getMahasiswaEnrollments() =>
      _get('/mahasiswa/enrollments');

  Future<Map<String, dynamic>> requestEnrollment(int matkulId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mahasiswa/enrollments/$matkulId'),
        headers: _authHeaders(token),
      ).timeout(_timeout);
      final data = _tryDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': _messageFrom(data, 'Berhasil mengajukan'),
        };
      }
      return {
        'success': false,
        'message': _messageFrom(data, 'Gagal mengajukan'),
      };
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  Future<Map<String, dynamic>> getDosenEnrollmentRequests() =>
      _get('/dosen/enrollments');

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
        headers: _authHeaders(token),
      ).timeout(_timeout);
      final data = _tryDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': _messageFrom(data, 'Berhasil')};
      }
      return {
        'success': false,
        'message': _messageFrom(data, 'Gagal memperbarui status'),
      };
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  // ── Notifications ─────────────────────────────────────

  Future<Map<String, dynamic>> getNotifications() => _get('/notifications');

  Future<Map<String, dynamic>> markNotificationRead(String id) =>
      _patch('/notifications/$id/read');

  Future<Map<String, dynamic>> markAllNotificationsRead() =>
      _patch('/notifications/mark-all-read');

  Future<Map<String, dynamic>> _patch(String path) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http
          .patch(Uri.parse('$baseUrl$path'), headers: _authHeaders(token))
          .timeout(_timeout);
      final data = _tryDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': _messageFrom(data, 'Berhasil')};
      }
      return {'success': false, 'message': _messageFrom(data, 'Gagal')};
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _authHeaders(token, json: true),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      final data = _tryDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data,
          'message': _messageFrom(data, 'Berhasil'),
        };
      }
      return {'success': false, 'message': _messageFrom(data, 'Gagal')};
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  // â”€â”€ Analytics â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<Map<String, dynamic>> getAnalytics() => _get('/analytics');

  // ── Reports ───────────────────────────────────────────

  Future<Map<String, dynamic>> getStudentReport({int? matkulId}) => _get(
    '/mahasiswa/reports${matkulId != null ? '?matkul_id=$matkulId' : ''}',
  );

  Future<Map<String, dynamic>> getDosenReportOptions() =>
      _get('/dosen/reports');

  Future<Map<String, dynamic>> generateDosenReport({
    required int matkulId,
    String? month,
  }) => _postJson('/dosen/reports/generate', {
    'matkul_id': matkulId,
    'month': month,
    'type': 'json',
  });

  // ── Profile ───────────────────────────────────────────

  Future<Map<String, dynamic>> updateMahasiswaProfile({
    String? jurusan,
    String? angkatan,
    String? phone,
    String? photo,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mahasiswa/profile'),
        headers: _authHeaders(token, json: true),
        body: jsonEncode({
          'jurusan': ?jurusan,
          'angkatan': ?angkatan,
          'phone': ?phone,
          'photo': ?photo,
        }),
      ).timeout(_timeout);
      final data = _tryDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': _messageFrom(data, 'Profil diperbarui'),
        };
      }
      return {
        'success': false,
        'message': _messageFrom(data, 'Gagal memperbarui profil'),
      };
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  Future<Map<String, dynamic>> getMahasiswaProfile() =>
      _get('/mahasiswa/profile');

  Future<Map<String, dynamic>> getDosenProfile() => _get('/dosen/profile');

  // ── Matkul management (dosen) ─────────────────────────

  Future<Map<String, dynamic>> getDosenMatkuls() => _get('/dosen/matkuls');

  Future<Map<String, dynamic>> getDosenSchedule() => _get('/dosen/schedule');

  Future<Map<String, dynamic>> getDosenPresences({
    int? matkulId,
    String? tanggal,
  }) {
    final params = <String>[];
    if (matkulId != null) params.add('matkul_id=$matkulId');
    if (tanggal != null && tanggal.isNotEmpty) params.add('tanggal=$tanggal');
    return _get(
      '/dosen/presences${params.isNotEmpty ? '?${params.join('&')}' : ''}',
    );
  }

  Future<Map<String, dynamic>> saveDosenPresences({
    required int matkulId,
    required String tanggal,
    required List<Map<String, dynamic>> presences,
  }) => _postJson('/dosen/presences', {
    'matkul_id': matkulId,
    'tanggal': tanggal,
    'presences': presences,
  });

  Future<Map<String, dynamic>> saveMatkul({
    int? id,
    required String kode,
    required String nama,
    required String hari,
    required String jam,
    String? ruangan,
    String? deskripsi,
    required int semester,
    required int credits,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    final body = jsonEncode({
      'kode': kode,
      'nama': nama,
      'hari': hari,
      'jam': jam,
      'ruangan': ruangan,
      'deskripsi': deskripsi,
      'semester': semester,
      'credits': credits,
    });
    try {
      final isUpdate = id != null;
      final uri = Uri.parse(
        isUpdate ? '$baseUrl/dosen/matkuls/$id' : '$baseUrl/dosen/matkuls',
      );
      final response = isUpdate
          ? await http
                .put(
                  uri,
                  headers: _authHeaders(token, json: true),
                  body: body,
                )
                .timeout(_timeout)
          : await http
                .post(
                  uri,
                  headers: _authHeaders(token, json: true),
                  body: body,
                )
                .timeout(_timeout);
      final data = _tryDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': _messageFrom(data, 'Mata kuliah disimpan'),
        };
      }
      return {
        'success': false,
        'message': _messageFrom(data, 'Gagal menyimpan mata kuliah'),
      };
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  Future<Map<String, dynamic>> deleteMatkul(int id) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/dosen/matkuls/$id'),
        headers: _authHeaders(token),
      ).timeout(_timeout);
      final data = _tryDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': _messageFrom(data, 'Mata kuliah dihapus'),
        };
      }
      return {
        'success': false,
        'message': _messageFrom(data, 'Gagal menghapus mata kuliah'),
      };
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  // ── Password reset ────────────────────────────────────

  Future<Map<String, dynamic>> sendOtpReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      ).timeout(_timeout);
      final data = _tryDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': _messageFrom(data, 'Gagal'),
      };
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
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
      ).timeout(_timeout);
      final data = _tryDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': _messageFrom(data, 'Gagal'),
      };
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  // ── AI Chat Assistant ─────────────────────────────────

  /// Sends a message to the role-aware AI agent (`POST /chat`).
  /// The backend resolves the user's role from the auth token, so the same
  /// call serves both dosen and mahasiswa — the reply adapts automatically.
  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'Belum login'};
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: _authHeaders(token, json: true),
        body: jsonEncode({'message': message}),
      ).timeout(const Duration(seconds: 40)); // AI replies are slower
      final data = _tryDecode(response.body);
      if (response.statusCode == 200 && data is Map && data['reply'] != null) {
        return {'success': true, 'reply': data['reply'].toString()};
      }
      return {
        'success': false,
        'message': _messageFrom(data, 'Asisten sedang tidak tersedia'),
      };
    } catch (e) {
      return {'success': false, 'message': _networkError(e)};
    }
  }

  // ── Attendance Analytics (dosen) ──────────────────────

  /// Get attendance data for weekly/monthly charts
  /// Returns: { week_number: count } for last 4 weeks or month_year: count for last 6 months
  Future<Map<String, dynamic>> getAttendanceAnalytics({
    int? matkulId,
    String period = 'week', // 'week' or 'month'
  }) {
    final params = <String>['period=$period'];
    if (matkulId != null) params.add('matkul_id=$matkulId');
    return _get(
      '/dosen/analytics/attendance${params.isNotEmpty ? '?${params.join('&')}' : ''}',
    );
  }

  /// Get attendance percentage by subject (mata kuliah)
  /// Returns: [{ matkul_id, matkul_nama, attendance_percentage, total_students }]
  Future<Map<String, dynamic>> getAttendanceBySubject() =>
      _get('/dosen/analytics/by-subject');

  /// Get students with attendance below threshold (< 75%)
  /// Returns: [{ id, name, nim, attendance_percentage, status }]
  Future<Map<String, dynamic>> getAtRiskStudents({double threshold = 75.0}) =>
      _get('/dosen/analytics/at-risk?threshold=$threshold');

  /// Get students absent today
  /// Returns: [{ id, name, nim, matkul_nama }]
  Future<Map<String, dynamic>> getAbsentToday() =>
      _get('/dosen/analytics/absent-today');
}
