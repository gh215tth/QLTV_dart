// screens/user/category_list_page.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'book_detail_page.dart';

class CategoryListPage extends StatefulWidget {
  final int? selectedCategoryId;
  final String? selectedCategoryName;
  final void Function()? onBorrowed;

  const CategoryListPage({
    super.key,
    this.selectedCategoryId,
    this.selectedCategoryName,
    this.onBorrowed,
  });

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  Future<List<Map<String, dynamic>>> _fetchBooksInCategory(int id) {
    return ApiService.instance.fetchBooksByCategory(id);
  }

  @override
  Widget build(BuildContext context) {
    // Nếu được truyền category cụ thể thì chỉ hiển thị danh mục đó
    if (widget.selectedCategoryId != null && widget.selectedCategoryName != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Danh mục: ${widget.selectedCategoryName}'),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchBooksInCategory(widget.selectedCategoryId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('❌ Lỗi tải sách: ${snapshot.error}'));
            }

            final books = snapshot.data ?? [];
            if (books.isEmpty) {
              return const Center(child: Text('Không có sách trong danh mục này.'));
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
                            onBorrowed: widget.onBorrowed,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      );
    }

    // Nếu không truyền gì thì hiển thị danh sách các danh mục
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService.instance.fetchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('❌ Lỗi tải danh mục: ${snapshot.error}'));
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const Center(child: Text('Không có danh mục nào.'));
        }

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ExpansionTile(
                  title: Text(
                    category['name'] ?? '',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchBooksInCategory(category['id']),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snap.hasError) {
                          return ListTile(title: Text('❌ Lỗi: ${snap.error}'));
                        }
                        final books = snap.data ?? [];
                        if (books.isEmpty) {
                          return const ListTile(title: Text('Không có sách.'));
                        }
                        return Column(
                          children: books.map((book) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                child: ListTile(
                                  leading: const Icon(Icons.menu_book_outlined, color: Colors.indigo),
                                  title: Text(book['title'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w500)),
                                  subtitle: Text(book['author'] ?? 'Không rõ tác giả'),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BookDetailPage(
                                          bookId: book['id'],
                                          onBorrowed: widget.onBorrowed,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
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
