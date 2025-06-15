// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();
  static final instance = ApiService._();

  final _storage = const FlutterSecureStorage();

  /// Dynamic host for Android emulator vs others
  String get _baseUrl {
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:3000/api';
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

  /// Login and store JWT token
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    late http.Response resp;
    try {
      resp = await http
          .post(
            url,
            headers: await _headers(),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw Exception('Không thể kết nối tới máy chủ.');
    }

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = body['token'] as String?; // Đổi từ 'accessToken' thành 'token'
      if (token == null) throw Exception('Phản hồi không hợp lệ từ server.');
      await _storage.write(key: 'ACCESS_TOKEN', value: token);
      return body['user'] as Map<String, dynamic>;
    } else if (resp.statusCode == 401) {
      throw Exception('Tên đăng nhập hoặc mật khẩu không đúng.');
    } else {
      throw Exception('Lỗi server (${resp.statusCode}).');
    }
  }

  /// Remove JWT token
  Future<void> logout() async {
    await _storage.delete(key: 'ACCESS_TOKEN');
  }

  /// ---------------- Users CRUD ----------------

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final url = Uri.parse('$_baseUrl/users');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được danh sách người dùng.');
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> user) async {
    final url = Uri.parse('$_baseUrl/users');
    final resp = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(user),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không tạo được người dùng (${resp.statusCode}).');
    }
  }

  Future<void> deleteUser(int id) async {
    final url = Uri.parse('$_baseUrl/users/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200) {
      throw Exception('Không xóa được người dùng (${resp.statusCode}).');
    }
  }

  /// ---------------- Books CRUD ----------------

  Future<List<Map<String, dynamic>>> fetchBooks() async {
    final url = Uri.parse('$_baseUrl/books');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được danh sách sách.');
    }
  }

  Future<Map<String, dynamic>> createBook(Map<String, dynamic> book) async {
    final url = Uri.parse('$_baseUrl/books');
    final resp = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(book),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không tạo được sách (${resp.statusCode}).');
    }
  }

  Future<Map<String, dynamic>> updateBook(int id, Map<String, dynamic> book) async {
    final url = Uri.parse('$_baseUrl/books/$id');
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
    final url = Uri.parse('$_baseUrl/books/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200) {
      throw Exception('Không xóa được sách (${resp.statusCode}).');
    }
  }

  /// ---------------- Loans CRUD ----------------

  Future<List<Map<String, dynamic>>> fetchLoans() async {
    final url = Uri.parse('$_baseUrl/loans');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được lịch sử mượn.');
    }
  }

  Future<Map<String, dynamic>> createLoan(Map<String, dynamic> loanRequest) async {
    final url = Uri.parse('$_baseUrl/loans');
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
    final url = Uri.parse('$_baseUrl/loans/$loanId/return');
    final resp = await http.post(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không trả được sách (${resp.statusCode}).');
    }
  }
}
