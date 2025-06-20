// screens/librarian/edit_user_page.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditUserPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditUserPage({super.key, required this.user});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  String _role = 'user';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user['username']);
    _emailController = TextEditingController(text: widget.user['email']);
    _role = widget.user['role'] ?? 'user';
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.instance.updateUser(
        widget.user['id'] as int,
        {
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _role,
          // nếu backend không cho phép update password tại đây thì bỏ dòng dưới
          'password': widget.user['password'],
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );

    } finally {
      if (!mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa người dùng')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
                validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v!.contains('@') ? null : 'Email không hợp lệ',
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Vai trò'),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('Người dùng')),
                  DropdownMenuItem(value: 'librarian', child: Text('Thủ thư')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _update,
                        child: const Text('Cập nhật'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
