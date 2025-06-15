import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> getBooks(String token, {String? query}) async {
    final uri = query != null && query.isNotEmpty
        ? Uri.parse('$baseUrl/books?search=$query')
        : Uri.parse('$baseUrl/books');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'books': jsonDecode(response.body)};
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch books');
    }
  }

  static Future<Map<String, dynamic>> getUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'users': jsonDecode(response.body)};
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch users');
    }
  }

  static Future<void> addBook(String token, String title, String author, String isbn, int publishedYear) async {
    final response = await http.post(
      Uri.parse('$baseUrl/books'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'author': author,
        'isbn': isbn,
        'published_year': publishedYear,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to add book');
    }
  }

  static Future<void> deleteBook(String token, int bookId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/books/$bookId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to delete book');
    }
  }
}