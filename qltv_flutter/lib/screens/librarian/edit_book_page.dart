// screens/librarian/edit_book_page.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditBookPage extends StatefulWidget {
  final Map<String, dynamic> book;

  const EditBookPage({super.key, required this.book});

  @override
  State<EditBookPage> createState() => _EditBookPageState();
}

class _EditBookPageState extends State<EditBookPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;

  int? _selectedCategoryId;
  int _selectedStatus = 0;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book['title']);
    _authorController = TextEditingController(text: widget.book['author']);
    _selectedCategoryId = widget.book['category_id'];
    _selectedStatus = widget.book['status'] ?? 0;
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await ApiService.instance.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh mục: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ApiService.instance.updateBook(widget.book['id'], {
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'category_id': _selectedCategoryId,
        'status': _selectedStatus,
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa sách')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tên sách'),
                validator: (value) => value!.trim().isEmpty ? 'Vui lòng nhập tên sách' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Tác giả'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: _categories
                    .map<DropdownMenuItem<int>>((cat) => DropdownMenuItem<int>(
                          value: cat['id'] as int,
                          child: Text(cat['name'] ?? ''),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategoryId = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Còn sách')),
                  DropdownMenuItem(value: 1, child: Text('Đã mượn')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Cập nhật'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
