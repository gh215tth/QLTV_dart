import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String _query = '';

  Future<void> _performSearch(String keyword) async {
    setState(() {
      _isLoading = true;
      _query = keyword.toLowerCase();
    });

    try {
      final books = await ApiService.instance.fetchBooks();
      final categories = await ApiService.instance.fetchCategories();

      if (!mounted) return; // ✅ Tránh lỗi khi dùng context sau async

      setState(() {
        _books = books
            .where((b) =>
                b['title']?.toLowerCase().contains(_query) == true ||
                b['author']?.toLowerCase().contains(_query) == true)
            .toList();

        _categories = categories
            .where((c) => c['name']?.toLowerCase().contains(_query) == true)
            .toList();
      });
    } catch (e) {
      if (!mounted) return; // ✅ An toàn
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tìm kiếm: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onSubmitted: _performSearch,
            decoration: InputDecoration(
              hintText: 'Nhập tên sách, tác giả hoặc danh mục...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _performSearch(_searchController.text),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            Expanded(
              child: ListView(
                children: [
                  if (_categories.isNotEmpty) ...[
                    const Text('Kết quả danh mục',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ..._categories.map((c) => ListTile(
                          leading: const Icon(Icons.category),
                          title: Text(c['name']),
                        )),
                    const Divider(),
                  ],
                  if (_books.isNotEmpty) ...[
                    const Text('Kết quả sách',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ..._books.map((b) => ListTile(
                          leading: const Icon(Icons.book),
                          title: Text(b['title']),
                          subtitle: Text(b['author'] ?? ''),
                        )),
                  ],
                  if (_books.isEmpty &&
                      _categories.isEmpty &&
                      _query.isNotEmpty)
                    const Center(child: Text('Không tìm thấy kết quả.')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
