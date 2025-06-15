import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
                trailing: Text('${book['available']}/${book['quantity']}'),
                onTap: () {
                  // TODO: Chuyển tới chi tiết hoặc chỉnh sửa sách
                },
              );
            },
          ),
        );
      },
    );
  }
}
