// screens/librarian/edit_librarian_page.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditLibrarianPage extends StatefulWidget {
  final Map<String, dynamic> librarian;
  const EditLibrarianPage({super.key, required this.librarian});

  @override
  State<EditLibrarianPage> createState() => _EditLibrarianPageState();
}

class _EditLibrarianPageState extends State<EditLibrarianPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.librarian['username']);
    _emailCtrl = TextEditingController(text: widget.librarian['email']);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.instance.updateLibrarian(
        widget.librarian['id'] as int,
        {
          'username': _usernameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa Thủ thư')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (v) => v!.isEmpty ? 'Nhập username' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => v!.contains('@') ? null : 'Email không hợp lệ',
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Lưu'),
                  ),
          ]),
        ),
      ),
    );
  }
}
