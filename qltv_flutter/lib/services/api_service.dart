// services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ApiService: Quản lý các request đến backend, lưu trữ token, IP server, và các thao tác CRUD cho user, sách, thủ thư, danh mục, phiếu mượn, v.v.
class ApiService {
  // Singleton pattern
  ApiService._();
  static final instance = ApiService._();

  // Storage cho token và user info
  final _storage = const FlutterSecureStorage();
  Future<String>? _baseUrlCache;

  // ===================== CẤU HÌNH SERVER/IP =====================
  /// Lấy baseUrl từ SharedPreferences (ưu tiên IP đã lưu, mặc định 10.0.2.2)
  Future<String> get _baseUrl async {
    if (_baseUrlCache != null) return _baseUrlCache!;
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('server_ip');
    final base = 'http://${savedIp ?? '10.0.2.2'}:3000/api';
    _baseUrlCache = Future.value(base);
    return _baseUrlCache!;
  }

  /// Lưu IP server vào SharedPreferences
  Future<void> setServerIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
  }

  /// Lấy IP server đã lưu
  Future<String?> getServerIP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_ip');
  }

  /// Xóa IP server đã lưu
  Future<void> clearServerIP() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_ip');
  }

  /// Lấy IP host từ backend và lưu vào SharedPreferences
  Future<void> fetchAndSaveHostIP() async {
    try {
      final defaultUrl = 'http://10.0.2.2:3000/host-ip';
      final resp = await http.get(Uri.parse(defaultUrl)).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['hostIp'] != null) {
          await setServerIP(data['hostIp']);
        } else if (data['hostIps'] != null && data['hostIps'].isNotEmpty) {
          await setServerIP(data['hostIps'][0]['address']);
        } else {
          throw Exception('Không tìm thấy địa chỉ IP.');
        }
      } else {
        throw Exception('Lỗi server (${resp.statusCode})');
      }
    } catch (e) {
      throw Exception('Không thể lấy địa chỉ IP từ server: $e');
    }
  }

  // ===================== HEADER & TOKEN =====================
  /// Tạo headers cho request, thêm Authorization nếu cần
  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.read(key: 'ACCESS_TOKEN');
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Lấy access token hiện tại
  Future<String?> getToken() async => await _storage.read(key: 'ACCESS_TOKEN');

  /// Lấy thông tin user hiện tại từ storage
  Future<Map<String, dynamic>> getCurrentUser() async {
    final jsonString = await _storage.read(key: 'LOGGED_IN_USER');
    if (jsonString == null) throw Exception('Không tìm thấy thông tin người dùng');
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Kiểm tra đã đăng nhập hay chưa
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'ACCESS_TOKEN');
    return token != null;
  }

  /// Đăng xuất, xóa token và user info (và IP nếu clearIP)
  Future<void> logout({bool clearIP = false}) async {
    await _storage.delete(key: 'ACCESS_TOKEN');
    await _storage.delete(key: 'LOGGED_IN_USER');
    if (clearIP) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('server_ip');
    }
  }

  // ===================== ĐĂNG NHẬP/ĐĂNG KÝ =====================
  /// Đăng nhập user thường
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final baseUrl = await _baseUrl;
      final url = Uri.parse('$baseUrl/users/login');
      final resp = await http.post(
        url,
        headers: await _headers(),
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = body['accessToken'] as String?;
        if (token == null) throw Exception('Phản hồi không hợp lệ từ server.');
        await _storage.write(key: 'ACCESS_TOKEN', value: token);
        await _storage.write(key: 'LOGGED_IN_USER', value: jsonEncode(body['user']));
        return body['user'] as Map<String, dynamic>;
      } else {
        final body = jsonDecode(resp.body);
        final message = body['message'] ?? 'Lỗi server (${resp.statusCode}).';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Không thể kết nối đến server: $e');
    }
  }

  /// Đăng nhập thủ thư
  Future<Map<String, dynamic>> loginLibrarian(String username, String password) async {
    try {
      final baseUrl = await _baseUrl;
      final url = Uri.parse('$baseUrl/librarians/login');
      final resp = await http.post(
        url,
        headers: await _headers(),
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = body['accessToken'] as String?;
        if (token == null) throw Exception('Phản hồi không hợp lệ từ server.');
        await _storage.write(key: 'ACCESS_TOKEN', value: token);
        await _storage.write(key: 'LOGGED_IN_USER', value: jsonEncode(body['librarian']));
        return body['librarian'] as Map<String, dynamic>;
      } else {
        final body = jsonDecode(resp.body);
        final message = body['message'] ?? 'Lỗi server (${resp.statusCode}).';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Không thể kết nối đến server: $e');
    }
  }

  /// Đăng ký user mới
  Future<Map<String, dynamic>> registerUser(Map<String, dynamic> user) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/users/register');
    final resp = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(user),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      final body = jsonDecode(resp.body);
      final kind = body['kind'];
      switch (kind) {
        case 'duplicate_username':
          throw Exception('Tên người dùng đã tồn tại.');
        case 'duplicate_email':
          throw Exception('Email đã được sử dụng.');
        default:
          throw Exception(body['message'] ?? 'Không thể đăng ký người dùng.');
      }
    }
  }

  /// Đăng ký user mới (shortcut)
  Future<void> register(String username, String email, String password) async {
    await registerUser({
      'username': username,
      'email': email,
      'password': password,
    });
  }

  // ===================== USER =====================
  /// Lấy danh sách user
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/users');
    final resp = await http.get(url, headers: await _headers(auth: true)).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được danh sách người dùng.');
    }
  }

  /// Tạo user mới
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> user) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/users');
    final resp = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(user),
    ).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không tạo được người dùng (${resp.statusCode}).');
    }
  }

  /// Lấy danh sách id sách đã mượn của user
  Future<List<int>> getBorrowedBookIds(int userId) async {
    try {
      final baseUrl = await _baseUrl;
      final url = Uri.parse('$baseUrl/users/$userId/borrowed-books');
      final resp = await http.get(url, headers: await _headers(auth: true))
        .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return List<int>.from(jsonDecode(resp.body));
      } else {
        final body = jsonDecode(resp.body);
        final message = body['message'] ?? 'Lỗi server (${resp.statusCode}).';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Không thể kết nối đến server: $e');
    }
  }

  /// Cập nhật user
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

  /// Xóa user
  Future<void> deleteUser(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/users/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Không xóa được người dùng (${resp.statusCode}).');
    }
  }

  /// Lấy user theo id
  Future<Map<String, dynamic>> fetchUserById(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/users/$id');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception('Không tải được thông tin người dùng (${resp.statusCode})');
    }
  }

  /// Lấy thông tin user hiện tại (me)
  Future<Map<String, dynamic>> fetchMyInfo() async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/users/me');
    final headers = await _headers(auth: true);
    final resp = await http.get(url, headers: headers);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không lấy được thông tin người dùng.');
    }
  }

  /// Cập nhật thông tin user hiện tại (me)
  Future<Map<String, dynamic>> updateMyInfo(Map<String, dynamic> data) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/users/me');
    final resp = await http.put(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không cập nhật được thông tin người dùng.');
    }
  }

  // ===================== SÁCH (BOOKS) =====================
  /// Lấy danh sách sách
  Future<List<Map<String, dynamic>>> fetchBooks() async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/books/v1');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được danh sách sách.');
    }
  }

  /// Lấy sách theo id
  Future<Map<String, dynamic>> fetchBookById(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/books/v1/$id');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không tải được sách chi tiết (${resp.statusCode})');
    }
  }

  /// Lấy top sách mượn nhiều
  Future<List<Map<String, dynamic>>> fetchTopBorrowedBooks({int limit = 10}) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/books/v1/top?limit=$limit');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      final body = jsonDecode(resp.body);
      final message = body['message'] ?? 'Không lấy được danh sách sách mượn nhiều.';
      throw Exception(message);
    }
  }

  /// Tạo sách mới
  Future<Map<String, dynamic>> createBook(Map<String, dynamic> book) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/books/v1');
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

  /// Cập nhật sách
  Future<Map<String, dynamic>> updateBook(int id, Map<String, dynamic> book) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/books/v1/$id');
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

  /// Xóa sách
  Future<void> deleteBook(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/books/v1/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200) {
      throw Exception('Không xóa được sách (${resp.statusCode}).');
    }
  }

  /// Lấy sách theo danh mục
  Future<List<Map<String, dynamic>>> fetchBooksByCategory(int categoryId) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/categories/v1/$categoryId/books');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được sách theo danh mục (${resp.statusCode}).');
    }
  }

  // ===================== DANH MỤC (CATEGORIES) =====================
  /// Lấy danh sách danh mục
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/categories/v1');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được danh mục.');
    }
  }

  /// Tạo danh mục mới
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/categories/v1');
    final resp = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    if (resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không tạo được danh mục (${resp.statusCode})');
    }
  }

  /// Cập nhật danh mục
  Future<Map<String, dynamic>> updateCategory(int id, Map<String, dynamic> data) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/categories/v1/$id');
    final resp = await http.put(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không cập nhật được danh mục (${resp.statusCode})');
    }
  }

  /// Xóa danh mục
  Future<void> deleteCategory(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/categories/v1/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Không xóa được danh mục (${resp.statusCode})');
    }
  }

  // ===================== THỦ THƯ (LIBRARIAN) =====================
  /// Lấy danh sách thủ thư
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

  /// Tạo thủ thư mới
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

  /// Cập nhật thủ thư
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

  /// Xóa thủ thư
  Future<void> deleteLibrarian(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/librarians/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Không xóa được thủ thư (${resp.statusCode}).');
    }
  }

  // ===================== PHIẾU MƯỢN (LOAN) =====================
  /// Lấy danh sách phiếu mượn
  Future<List<Map<String, dynamic>>> fetchLoans() async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans/v1');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được lịch sử mượn.');
    }
  }

  /// Lấy phiếu mượn theo id
  Future<Map<String, dynamic>> fetchLoanById(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans/v1/$id');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không lấy được phiếu mượn (${resp.statusCode})');
    }
  }

  /// Tạo phiếu mượn mới
  Future<Map<String, dynamic>> createLoan(Map<String, dynamic> loanRequest) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans/v1');
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

  /// Cập nhật phiếu mượn
  Future<Map<String, dynamic>> updateLoan(int id, Map<String, dynamic> data) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans/v1/$id');
    final resp = await http.put(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không cập nhật được phiếu mượn (${resp.statusCode})');
    }
  }

  /// Xóa phiếu mượn
  Future<void> deleteLoan(int loanId) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans/v1/$loanId');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Không xóa được phiếu mượn (${resp.statusCode})');
    }
  }

  /// Trả sách (POST /loans/v1/{loanId}/return)
  Future<Map<String, dynamic>> returnLoan(int loanId) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans/v1/$loanId/return');
    final resp = await http.post(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không trả được sách (${resp.statusCode}).');
    }
  }
  
  // 
  Future<List<Map<String, dynamic>>> fetchAllLoans() async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans/v1/all');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được danh sách phiếu mượn.');
    }
  }

  // ===================== CHI TIẾT MƯỢN (LOAN ITEM) =====================
  /// Lấy danh sách chi tiết mượn theo loanId
  Future<List<Map<String, dynamic>>> fetchLoanItemsByLoanId(int loanId) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loan-items/v1/loan/$loanId');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không lấy được danh sách chi tiết mượn (${resp.statusCode})');
    }
  }

  /// Tạo chi tiết mượn
  Future<Map<String, dynamic>> createLoanItem(Map<String, dynamic> item) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loan-items/v1');
    final resp = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(item),
    );
    if (resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      final body = jsonDecode(resp.body);
      final kind = body['kind'];
      switch (kind) {
        case 'already_borrowed':
          throw Exception('Bạn đã mượn sách này và chưa trả.');
        case 'book_out_of_stock':
          throw Exception('Sách đã hết.');
        case 'invalid_book':
          throw Exception('Sách không tồn tại.');
        case 'invalid_loan':
          throw Exception('Phiếu mượn không hợp lệ.');
        default:
          throw Exception(body['message'] ?? 'Không tạo được chi tiết mượn.');
      }
    }
  }

  /// Tạo phiếu mượn kèm chi tiết mượn
  Future<Map<String, dynamic>> createLoanWithItem(Map<String, dynamic> data) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans/v1/with-item');
    final resp = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    if (resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      final body = jsonDecode(resp.body);
      final kind = body['kind'];
      switch (kind) {
        case 'already_borrowed':
          throw Exception('Bạn đã mượn sách này và chưa trả.');
        case 'book_out_of_stock':
          throw Exception('Sách đã hết.');
        case 'invalid_user':
          throw Exception('Người dùng không tồn tại.');
        case 'invalid_book':
          throw Exception('Sách không tồn tại.');
        default:
          throw Exception(body['message'] ?? 'Không tạo được phiếu mượn.');
      }
    }
  }

  Future<Map<String, dynamic>> fetchLoanWithItems(int loanId) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans/v1/$loanId/details');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Không lấy được chi tiết phiếu mượn (${resp.statusCode})');
    }
  }

  /// Cập nhật chi tiết mượn
  Future<Map<String, dynamic>> updateLoanItem(int id, Map<String, dynamic> data) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loan-items/v1/$id');
    final resp = await http.put(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode(data),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      final body = jsonDecode(resp.body);
      final kind = body['kind'];
      switch (kind) {
        case 'invalid_update_loan_id':
          throw Exception('Không được phép thay đổi mã phiếu mượn.');
        case 'invalid_book':
          throw Exception('Sách không tồn tại.');
        case 'not_found':
          throw Exception('Không tìm thấy chi tiết mượn.');
        default:
          throw Exception(body['message'] ?? 'Không cập nhật được chi tiết mượn.');
      }
    }
  }

  /// Xóa chi tiết mượn
  Future<void> deleteLoanItem(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loan-items/v1/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Không xóa được chi tiết mượn (${resp.statusCode})'); 
    }
  }
}
