import 'package:flutter/material.dart';
// import các widget cần thiết, ví dụ DashboardPage nếu có

class LibrarianHome extends StatefulWidget {
  const LibrarianHome({super.key});

  @override
  State<LibrarianHome> createState() => _LibrarianHomeState();
}

class _LibrarianHomeState extends State<LibrarianHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Đảm bảo DashboardPage đã được định nghĩa hoặc import đúng
    return Scaffold(
      appBar: AppBar(title: const Text('Librarian Home')),
      body: Center(child: Text('Welcome, Librarian!')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Books'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
