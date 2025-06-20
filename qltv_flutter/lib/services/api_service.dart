// services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class ApiService {
  ApiService._();
  static final instance = ApiService._();

  final _storage = const FlutterSecureStorage();
  final _deviceInfo = DeviceInfoPlugin();

  /// Determine base URL based on emulator vs real device
  Future<String> get _baseUrl async {
    bool isEmulator = false;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        isEmulator = !androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        isEmulator = !iosInfo.isPhysicalDevice;
      }
    } catch (_) {
      isEmulator = false;
    }

    if (Platform.isAndroid && isEmulator) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://192.168.5.100:3000/api';
  }

  /// Common headers; add Authorization when needed
  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.read(key: 'ACCESS_TOKEN');
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// ---------------- Authentication ----------------

  Future<Map<String, dynamic>> login(String username, String password) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/users/login');
    final resp = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = body['accessToken'] as String?;
      if (token == null) throw Exception('Phản hồi không hợp lệ từ server.');
      await _storage.write(key: 'ACCESS_TOKEN', value: token);
      await _storage.write(key: 'LOGGED_IN_USER', value: jsonEncode(body['user']));
      return body['user'] as Map<String, dynamic>;
    } else if (resp.statusCode == 401) {
      throw Exception('Tên đăng nhập hoặc mật khẩu không đúng.');
    } else {
      throw Exception('Lỗi server (${resp.statusCode}).');
    }
  }

  Future<Map<String, dynamic>> loginLibrarian(String username, String password) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/librarians/login');
    final resp = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = body['accessToken'] as String?;
      if (token == null) throw Exception('Phản hồi không hợp lệ từ server.');
      await _storage.write(key: 'ACCESS_TOKEN', value: token);
      await _storage.write(key: 'LOGGED_IN_USER', value: jsonEncode(body['librarian']));
      return body['librarian'] as Map<String, dynamic>;
    } else if (resp.statusCode == 401) {
      throw Exception('Tên đăng nhập hoặc mật khẩu không đúng.');
    } else {
      throw Exception('Lỗi server (${resp.statusCode}).');
    }
  }

  Future<String?> getToken() async => await _storage.read(key: 'ACCESS_TOKEN');

  Future<Map<String, dynamic>> getCurrentUser() async {
    final jsonString = await _storage.read(key: 'LOGGED_IN_USER');
    if (jsonString == null) throw Exception('Không tìm thấy thông tin người dùng');
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'ACCESS_TOKEN');
    await _storage.delete(key: 'LOGGED_IN_USER');
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/users');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được danh sách người dùng.');
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> user) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/users');
    final resp = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(user),
    );
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không tạo được người dùng (${resp.statusCode}).');
    }
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/users/$id');
    final resp = await http.put(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không cập nhật được người dùng (${resp.statusCode}).');
    }
  }

  Future<void> deleteUser(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/users/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Không xóa được người dùng (${resp.statusCode}).');
    }
  }

  Future<List<Map<String, dynamic>>> fetchBooks() async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/books');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được danh sách sách.');
    }
  }

  Future<Map<String, dynamic>> createBook(Map<String, dynamic> book) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/books');
    final resp = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(book),
    );
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không tạo được sách (${resp.statusCode}).');
    }
  }

  Future<Map<String, dynamic>> updateBook(int id, Map<String, dynamic> book) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/books/$id');
    final resp = await http.put(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(book),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không cập nhật được sách (${resp.statusCode}).');
    }
  }

  Future<void> deleteBook(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/books/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200) {
      throw Exception('Không xóa được sách (${resp.statusCode}).');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLoans() async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được lịch sử mượn.');
    }
  }

  Future<Map<String, dynamic>> createLoan(Map<String, dynamic> loanRequest) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans');
    final resp = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(loanRequest),
    );
    if (resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không tạo được phiếu mượn (${resp.statusCode}).');
    }
  }

  Future<Map<String, dynamic>> returnLoan(int loanId) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans/$loanId/return');
    final resp = await http.post(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không trả được sách (${resp.statusCode}).');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLibrarians() async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/librarians');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được danh sách thủ thư.');
    }
  }

  Future<Map<String, dynamic>> createLibrarian(Map<String, dynamic> data) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/librarians');
    final resp = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    if (resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không tạo được thủ thư (${resp.statusCode}).');
    }
  }

  /// Cập nhật thủ thư (PUT /api/librarians/{id})
  Future<Map<String, dynamic>> updateLibrarian(int id, Map<String, dynamic> data) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/librarians/$id');
    final resp = await http.put(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không cập nhật được thủ thư (${resp.statusCode}).');
    }
  }

  Future<void> deleteLibrarian(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/librarians/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Không xóa được thủ thư (${resp.statusCode}).');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/categories');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được danh mục.');
    }
  }
}
