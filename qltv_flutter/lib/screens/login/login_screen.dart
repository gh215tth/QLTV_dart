import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  String _selectedRole = 'user'; // default

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      final user = _selectedRole == 'librarian'
          ? await ApiService.instance.loginLibrarian(username, password)
          : await ApiService.instance.login(username, password);

      if (!mounted) return;

      // ✅ Sử dụng user để tránh cảnh báo unused
      debugPrint('Đăng nhập thành công với user: ${user['username']}');

      final route = _selectedRole == 'librarian' ? '/librarianHome' : '/userHome';
      Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = _selectedRole == 'user';
    final isLibrarian = _selectedRole == 'librarian';

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Quản lý thư viện",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 36,
            )),
            const SizedBox(height: 60),
            Image.asset('assets/images/logo.png', height: 200),
            const SizedBox(height: 32),
            ToggleButtons(
              selectedColor: Colors.white, // Màu chữ khi chọn
              color: Colors.blue,         // Màu chữ khi chưa chọn
              fillColor: Colors.blue,      // ✅ Màu nền khi được chọn
              borderColor: Colors.blue,    // ✅ Màu viền
              selectedBorderColor: Colors.blue, // ✅ Màu viền khi được chọn
              isSelected: [isUser, isLibrarian],
              onPressed: (index) {
                setState(() {
                  _selectedRole = index == 0 ? 'user' : 'librarian';
                });
              },
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Người dùng"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Thủ thư"),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // ✅ Màu nền
                        foregroundColor: Colors.white,      // ✅ Màu chữ
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // ✅ Bo tròn nút
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16), // ✅ Tăng chiều cao
                      ),
                      onPressed: _login,
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
