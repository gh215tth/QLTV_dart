// screens/common/search_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../user/book_detail_page.dart';
import '../user/category_list_page.dart';
import 'package:diacritic/diacritic.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String _query = '';
  bool _isLibrarian = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _checkIfLibrarian();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final keyword = _searchController.text.trim();
      final normalized = _normalize(keyword);
      if (normalized.isNotEmpty && normalized != _query) {
        _performSearch(keyword);
      }
    });
  }

  Future<void> _checkIfLibrarian() async {
    final user = await ApiService.instance.getCurrentUser();
    if (mounted) {
      setState(() => _isLibrarian = user['role'] == 'librarian');
    }
  }

  String _normalize(String input) => removeDiacritics(input.toLowerCase());

  Future<void> _performSearch(String keyword) async {
    setState(() {
      _isLoading = true;
      _query = _normalize(keyword);
    });

    try {
      final books = await ApiService.instance.fetchBooks();
      final categories = await ApiService.instance.fetchCategories();
      List<Map<String, dynamic>> users = [];

      if (_isLibrarian) {
        users = await ApiService.instance.fetchUsers();
      }

      if (!mounted) return;

      setState(() {
        _books = books
            .where((b) =>
                _normalize(b['title'] ?? '').contains(_query) ||
                _normalize(b['author'] ?? '').contains(_query))
            .toList();

        _categories = categories
            .where((c) => _normalize(c['name'] ?? '').contains(_query))
            .toList();

        _users = _isLibrarian
            ? users
                .where((u) =>
                    _normalize(u['username'] ?? '').contains(_query) ||
                    _normalize(u['name'] ?? '').contains(_query))
                .toList()
            : [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi tìm kiếm: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  TextSpan highlightText(String text, String query) {
    final normalized = _normalize(text);
    final index = normalized.indexOf(query);
    if (query.isEmpty || index == -1) {
      return TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black),
      );
    }

    return TextSpan(children: [
      TextSpan(
        text: text.substring(0, index),
        style: const TextStyle(color: Colors.black),
      ),
      TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ),
      TextSpan(
        text: text.substring(index + query.length),
        style: const TextStyle(color: Colors.black),
      ),
    ]);
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
            decoration: InputDecoration(
              hintText: 'Nhập tên sách, tác giả, danh mục hoặc người dùng...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _performSearch(_searchController.text),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: ListView(
                children: [
                  if (_categories.isNotEmpty) ...[
                    const Text('📂 Danh mục',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ..._categories.map((c) => ListTile(
                          leading: const Icon(Icons.category),
                          title: RichText(
                            text: highlightText(c['name'], _query),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryListPage(
                                  selectedCategoryId: c['id'],
                                  selectedCategoryName: c['name'],
                                ),
                              ),
                            );
                          },
                        )),
                    const Divider(),
                  ],
                  if (_books.isNotEmpty) ...[
                    const Text('📚 Sách',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ..._books.map((b) => ListTile(
                          leading: const Icon(Icons.book),
                          title: RichText(
                            text: highlightText(b['title'] ?? '[Không rõ tên]', _query),
                          ),
                          subtitle: RichText(
                            text: highlightText(b['author'] ?? '', _query),
                          ),
                          onTap: () {
                            if (b['id'] != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookDetailPage(bookId: b['id']),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('❌ Không thể mở chi tiết sách: thiếu ID.')),
                              );
                            }
                          },
                        )),
                    const Divider(),
                  ],
                  if (_isLibrarian && _users.isNotEmpty) ...[
                    const Text('👤 Người dùng',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ..._users.map((u) => ListTile(
                          leading: const Icon(Icons.person),
                          title: RichText(
                            text: highlightText(u['name'] ?? u['username'], _query),
                          ),
                          subtitle: RichText(
                            text: highlightText(u['username'] ?? '', _query),
                          ),
                        )),
                  ],
                  if (_query.isNotEmpty &&
                      _books.isEmpty &&
                      _categories.isEmpty &&
                      (_users.isEmpty || !_isLibrarian))
                    const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(
                        child: Text('😕 Không tìm thấy kết quả.'),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
