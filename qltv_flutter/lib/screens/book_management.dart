import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BookManagementPage extends StatefulWidget {
  const BookManagementPage({super.key});

  @override
  State<BookManagementPage> createState() => _BookManagementPageState();
}

class _BookManagementPageState extends State<BookManagementPage> {
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
    try {
      await ApiService.instance.deleteBook(id);
      if (!mounted) return;
      setState(() => _loadBooks());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa sách thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa sách: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
        return Scaffold(
          body: books.isEmpty
              ? const Center(child: Text('Chưa có sách nào.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return ListTile(
                      leading: const Icon(Icons.book),
                      title: Text(book['title'] ?? ''),
                      subtitle: Text('Tác giả: ${book['author'] ?? ''}'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // TODO: Chuyển tới form sửa sách
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
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              // TODO: Thêm logic thêm sách nếu có
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

// Nếu cần, để các extension hoặc class phụ ở đây, ngoài class chính
// class AnotherPage extends StatelessWidget { ... }
