// screens/book_list.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class BookListPage extends StatefulWidget {
  const BookListPage({super.key});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  late Future<List<Map<String, dynamic>>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() {
    _booksFuture = ApiService.instance.fetchBooks();
  }

  Future<void> _deleteBook(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa sách này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.instance.deleteBook(id);
        if (!mounted) return;
        setState(() => _loadBooks());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Sách')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi khi tải sách:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final books = snapshot.data!;
          if (books.isEmpty) {
            return const Center(child: Text('Chưa có sách nào.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _loadBooks());
              await _booksFuture;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  leading: const Icon(Icons.book),
                  title: Text(book['title'] ?? ''),
                  subtitle: Text('Tác giả: ${book['author'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // TODO: điều hướng sang màn sửa sách
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteBook(book['id'] as int),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: điều hướng sang màn thêm sách
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
