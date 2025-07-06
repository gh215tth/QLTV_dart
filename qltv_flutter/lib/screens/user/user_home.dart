import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'category_books_page.dart';
import 'borrow_history.dart';
import 'user_profile.dart';
import 'book_detail_page.dart';
import '../common/search_page.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _currentIndex = 0;
  String? _username;
  int _borrowedCount = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _pages = [
      const SizedBox(),
      CategoryBooksPage(onBorrowed: _refreshBorrowedCount),
      BorrowHistoryPage(onReturn: _refreshBorrowedCount),
      SearchPage(),
      const UserProfilePage(),
    ];
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await ApiService.instance.getCurrentUser();
      final borrowedBookIds = await ApiService.instance.getBorrowedBookIds(user['id']);
      if (mounted) {
        setState(() {
          _username = user['username'];
          _borrowedCount = borrowedBookIds.length;
        });
      }
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  Future<void> _refreshBorrowedCount() async {
    try {
      final user = await ApiService.instance.getCurrentUser();
      final borrowedBookIds = await ApiService.instance.getBorrowedBookIds(user['id']);
      if (mounted) {
        setState(() {
          _borrowedCount = borrowedBookIds.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.instance.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _currentIndex == 0
          ? HomePageUser(username: _username, borrowedCount: _borrowedCount, onBorrowed: _refreshBorrowedCount)
          : _pages[_currentIndex],
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Thông tin'),
        ],
      ),
    );
  }
}

class HomePageUser extends StatelessWidget {
  final String? username;
  final int borrowedCount;
  final VoidCallback? onBorrowed;

  const HomePageUser({super.key, this.username, required this.borrowedCount, this.onBorrowed});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Chào mừng đến với Thư viện HPC',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      username != null ? '$username!' : 'Null',
                      style: const TextStyle(fontSize: 22, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sách đang mượn: $borrowedCount sách.',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              "📚 Danh sách sách nổi bật",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 6),
          FeaturedBooksCarousel(onBorrowed: onBorrowed),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class FeaturedBooksCarousel extends StatefulWidget {
  final VoidCallback? onBorrowed;

  const FeaturedBooksCarousel({super.key, this.onBorrowed});

  @override
  State<FeaturedBooksCarousel> createState() => _FeaturedBooksCarouselState();
}

class _FeaturedBooksCarouselState extends State<FeaturedBooksCarousel> {
  List<Map<String, dynamic>> _books = [];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService.instance.fetchBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('❌ Lỗi tải sách nổi bật: ${snapshot.error}'));
        }

        _books = (snapshot.data ?? [])
            .where((b) => (b['total_borrowed'] ?? 0) > 0)
            .take(5)
            .toList();

        if (_books.isEmpty) {
          return const Center(child: Text('Không có sách nổi bật.'));
        }

        return ListView.builder(
          itemCount: _books.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final book = _books[index];
            return GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookDetailPage(
                      bookId: book['id'],
                      onBorrowed: () {
                        widget.onBorrowed?.call();
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blue.shade100),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.book, color: Colors.blue, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book['title'] ?? 'Không tiêu đề',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book['author'] ?? 'Không rõ tác giả',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Số lần được mượn: ${book['total_borrowed']} lượt',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

