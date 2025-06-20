import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'user_management.dart';
import 'book_management.dart';
import 'librarian_management.dart';
import '../common/search_page.dart';

class LibrarianHome extends StatefulWidget {
  const LibrarianHome({super.key});

  @override
  State<LibrarianHome> createState() => _LibrarianHomeState();
}

class _LibrarianHomeState extends State<LibrarianHome> {
  int _currentIndex = 0;
  String? _username;

  final List<Widget> _pages = const [
    UserManagementPage(),
    BookManagementPage(),
    LibrarianManagementPage(),
    SearchPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadLibrarianInfo();
  }

  Future<void> _loadLibrarianInfo() async {
    final token = await ApiService.instance.getToken();
    if (token != null) {
      final user = await ApiService.instance.getCurrentUser();
      if (mounted) {
        setState(() {
          _username = user['username'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_username != null ? 'Thủ thư: $_username' : 'Librarian Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.instance.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.blue,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Người dùng'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Sách'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Thủ thư'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
        ],
      ),
    );
  }
}
