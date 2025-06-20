import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CategoryListPage extends StatefulWidget {
  AppBar get appBar => AppBar(
        title: const Text('Danh mục sách'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      );
  const CategoryListPage({super.key});
  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  late Future<List<Map<String, dynamic>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ApiService.instance.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi khi tải danh mục:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final categories = snapshot.data!;
        if (categories.isEmpty) {
          return const Center(child: Text('Không có danh mục nào.'));
        }

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              leading: const Icon(Icons.category, color: Colors.blue),
              title: Text(category['name'] ?? '', style: const TextStyle(color: Colors.blue)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryBooksPage(categoryId: category['id'], categoryName: category['name']),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class CategoryBooksPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryBooksPage({super.key, required this.categoryId, required this.categoryName});

  @override
  State<CategoryBooksPage> createState() => _CategoryBooksPageState();
}

class _CategoryBooksPageState extends State<CategoryBooksPage> {
  late Future<List<Map<String, dynamic>>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = _loadBooksInCategory(widget.categoryId);
  }

  Future<List<Map<String, dynamic>>> _loadBooksInCategory(int categoryId) async {
    final allBooks = await ApiService.instance.fetchBooks();
    return allBooks.where((book) => book['category_id'] == categoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Danh mục: ${widget.categoryName}')),
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
            return const Center(child: Text('Không có sách trong danh mục này.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                leading: const Icon(Icons.book),
                title: Text(book['title'] ?? ''),
                subtitle: Text(book['author'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
