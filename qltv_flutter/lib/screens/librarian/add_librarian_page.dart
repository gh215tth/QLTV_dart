// screens/librarian/add_librarian_page.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AddLibrarianPage extends StatefulWidget {
  const AddLibrarianPage({super.key});

  @override
  State<AddLibrarianPage> createState() => _AddLibrarianPageState();
}

class _AddLibrarianPageState extends State<AddLibrarianPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.instance.createLibrarian({
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
      });
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
      appBar: AppBar(title: const Text('Thêm Thủ thư')),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (v) => v!.length >= 6 ? null : 'Password ≥ 6 ký tự',
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Thêm'),
                  ),
          ]),
        ),
      ),
    );
  }
}
