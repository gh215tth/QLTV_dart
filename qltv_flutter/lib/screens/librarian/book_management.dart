// screens/book_management.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'add_book_page.dart';
import 'edit_book_page.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa sách này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm != true) return;

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
        SnackBar(content: Text('Lỗi khi xóa: $e')),
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
              'Lỗi khi tải danh sách sách:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final books = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('Quản lý Sách')),
          body: books.isEmpty
              ? const Center(child: Text('Chưa có sách nào.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.book),
                        title: Text(book['title'] ?? ''),
                        subtitle: Text(book['author'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final success = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditBookPage(book: book),
                                  ),
                                );
                                if (success == true) setState(() => _loadBooks());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteBook(book['id'] as int),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () async {
              final success = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddBookPage()),
              );
              if (success == true) setState(() => _loadBooks());
            },
          ),
        );
      },
    );
  }
}
