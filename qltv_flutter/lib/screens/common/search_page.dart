import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
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
      _performSearch(_searchController.text);
    });
  }

  Future<void> _checkIfLibrarian() async {
    final user = await ApiService.instance.getCurrentUser();
    setState(() {
      _isLibrarian = user['role'] == 'librarian';
    });
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

        if (_isLibrarian) {
          _users = users
              .where((u) =>
                  _normalize(u['username'] ?? '').contains(_query) ||
                  _normalize(u['name'] ?? '').contains(_query))
              .toList();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tìm kiếm: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  TextSpan highlightText(String text, String query) {
    final normalized = removeDiacritics(text.toLowerCase());
    final index = normalized.indexOf(query);
    if (index == -1) return TextSpan(text: text);

    return TextSpan(children: [
      TextSpan(text: text.substring(0, index)),
      TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ),
      TextSpan(text: text.substring(index + query.length)),
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
                          title: RichText(
                            text: highlightText(c['name'], _query),
                          ),
                        )),
                    const Divider(),
                  ],
                  if (_books.isNotEmpty) ...[
                    const Text('Kết quả sách',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ..._books.map((b) => ListTile(
                          leading: const Icon(Icons.book),
                          title: RichText(
                            text: highlightText(b['title'], _query),
                          ),
                          subtitle: RichText(
                            text: highlightText(b['author'] ?? '', _query),
                          ),
                        )),
                    const Divider(),
                  ],
                  if (_isLibrarian && _users.isNotEmpty) ...[
                    const Text('Kết quả người dùng',
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
                  if (_books.isEmpty &&
                      _categories.isEmpty &&
                      (_users.isEmpty || !_isLibrarian) &&
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
