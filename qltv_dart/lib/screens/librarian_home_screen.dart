import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LibrarianHomeScreen extends StatefulWidget {
  const LibrarianHomeScreen({super.key});

  @override
  State<LibrarianHomeScreen> createState() => _LibrarianHomeScreenState();
}

class _LibrarianHomeScreenState extends State<LibrarianHomeScreen> {
  List<dynamic> _books = [];
  List<dynamic> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _fetchUsers();
  }

  Future<void> _fetchBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await ApiService.getBooks(token!);
      setState(() {
        _books = response['books'];
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await ApiService.getUsers(token!);
      setState(() {
        _users = response['users'];
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addBook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      await ApiService.addBook(
        token!,
        _titleController.text,
        _authorController.text,
        _isbnController.text,
        int.tryParse(_yearController.text) ?? 0,
      );
      _fetchBooks(); // Refresh book list
      _titleController.clear();
      _authorController.clear();
      _isbnController.clear();
      _yearController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm sách thành công!')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Thủ thư'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thêm sách mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(labelText: 'Tác giả', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _isbnController,
              decoration: const InputDecoration(labelText: 'ISBN', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(labelText: 'Năm xuất bản', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addBook,
              child: const Text('Thêm sách'),
            ),
            const SizedBox(height: 16),
            const Text('Danh sách sách', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _books.length,
                          itemBuilder: (context, index) {
                            final book = _books[index];
                            return ListTile(
                              title: Text(book['title']),
                              subtitle: Text('Tác giả: ${book['author']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  try {
                                    final prefs = await SharedPreferences.getInstance();
                                    final token = prefs.getString('token');
                                    await ApiService.deleteBook(token!, book['id']);
                                    _fetchBooks();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Xóa sách thành công!')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
            const SizedBox(height: 16),
            const Text('Danh sách người dùng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return ListTile(
                    title: Text(user['username']),
                    subtitle: Text('Email: ${user['email']} - Vai trò: ${user['role']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}