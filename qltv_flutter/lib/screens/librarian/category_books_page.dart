// screens/librarian/category_books_page.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'edit_book_page.dart';

class CategoryBooksPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryBooksPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryBooksPage> createState() => _CategoryBooksPageState();
}

class _CategoryBooksPageState extends State<CategoryBooksPage> {
  late Future<List<Map<String, dynamic>>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() {
    _booksFuture = ApiService.instance.fetchBooksByCategory(widget.categoryId);
  }

  Future<void> _deleteBook(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa sách này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
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
        SnackBar(content: Text('Lỗi khi xóa sách: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Danh sách sách: ${widget.categoryName}')),
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
            return const Center(child: Text('Chưa có sách trong danh mục này.'));
          }

          return ListView.separated(
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
          );
        },
      ),
    );
  }
}
