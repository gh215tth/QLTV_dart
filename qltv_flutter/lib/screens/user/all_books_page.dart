// screens/user/all_books_page.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'book_detail_page.dart';

class AllBooksPage extends StatelessWidget {
  final void Function()? onBorrowed;

  const AllBooksPage({super.key, this.onBorrowed});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService.instance.fetchBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('❌ Lỗi tải sách: ${snapshot.error}'));
        }

        final books = snapshot.data ?? [];
        if (books.isEmpty) {
          return const Center(child: Text('Không có sách nào.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.menu_book_outlined, color: Colors.indigo),
                title: Text(book['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(book['author'] ?? 'Không rõ tác giả'),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookDetailPage(
                        bookId: book['id'],
                        onBorrowed: onBorrowed,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
