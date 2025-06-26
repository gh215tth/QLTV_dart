// screens/librarian/librarian_home.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'user_management.dart';
import 'category_management.dart';
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

  final List<Widget> _pages = [
    const UserManagementPage(),
    const CategoryManagementPage(),
    const LibrarianManagementPage(),
    const SearchPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadLibrarianInfo();
  }

  Future<void> _loadLibrarianInfo() async {
    try {
      final token = await ApiService.instance.getToken();
      if (token != null) {
        final user = await ApiService.instance.getCurrentUser();
        if (!mounted) return;
        setState(() => _username = user['username']);
      }
    } catch (e) {
      debugPrint('Lỗi khi lấy thông tin thủ thư: $e');
    }
  }

  void _onLogout() async {
    await ApiService.instance.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_username != null ? 'Thủ thư: $_username' : 'Trang thủ thư'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _onLogout,
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.blue,
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

