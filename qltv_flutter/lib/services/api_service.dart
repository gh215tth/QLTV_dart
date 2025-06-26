// services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();
  static final instance = ApiService._();

  final _storage = const FlutterSecureStorage();

  Future<String> get _baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('server_ip');
    if (savedIp != null && savedIp.isNotEmpty) {
      return 'http://$savedIp:3000/api';
    }
    return 'http://192.168.5.106:3000/api';
  }
  Future<void> setServerIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
  }

  Future<String?> getServerIP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_ip');
  }

  Future<void> clearServerIP() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_ip');
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.read(key: 'ACCESS_TOKEN');
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

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

  Future<String?> getToken() async => await _storage.read(key: 'ACCESS_TOKEN');

  Future<Map<String, dynamic>> getCurrentUser() async {
    final jsonString = await _storage.read(key: 'LOGGED_IN_USER');
    if (jsonString == null) throw Exception('Không tìm thấy thông tin người dùng');
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'ACCESS_TOKEN');
    return token != null;
  }

  Future<void> logout({bool clearIP = false}) async {
    await _storage.delete(key: 'ACCESS_TOKEN');
    await _storage.delete(key: 'LOGGED_IN_USER');
    if (clearIP) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('server_ip');
    }
  }

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
    final url = Uri.parse('$baseUrl/books/v1');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được danh sách sách.');
    }
  }

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

  Future<void> deleteBook(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/books/v1/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200) {
      throw Exception('Không xóa được sách (${resp.statusCode}).');
    }
  }

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

  Future<void> deleteLoan(int loanId) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loans/v1/$loanId');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Không xóa được phiếu mượn (${resp.statusCode})');
    }
  }

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
    final url = Uri.parse('$baseUrl/categories/v1');
    final resp = await http.get(url, headers: await _headers(auth: true));
    if (resp.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(resp.body));
    } else {
      throw Exception('Không tải được danh mục.');
    }
  }

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

  Future<void> deleteLoanItem(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/loan-items/v1/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Không xóa được chi tiết mượn (${resp.statusCode})'); 
    }
  }

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

  Future<void> deleteCategory(int id) async {
    final baseUrl = await _baseUrl;
    final url = Uri.parse('$baseUrl/categories/v1/$id');
    final resp = await http.delete(url, headers: await _headers(auth: true));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Không xóa được danh mục (${resp.statusCode})');
    }
  }

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
}
