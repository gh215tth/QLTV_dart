import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'category_list.dart';
import 'borrow_history.dart';
import '../common/search_page.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _currentIndex = 0;
  String? _username;

  final List<Widget> _pages = [
    const HomePageUser(),
    CategoryListPage(),
    BorrowHistoryPage(),
    SearchPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
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
        title: Text(_username != null ? 'Xin chào, $_username' : 'Trang người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.instance.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/');
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Danh mục'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Đã mượn'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
        ],
      ),
    );
  }
}

class HomePageUser extends StatelessWidget {
  const HomePageUser({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Chào mừng bạn đến thư viện!',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }
}
