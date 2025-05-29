import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget
{
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
{
  String _role = 'user';

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding
      (
        padding: const EdgeInsets.all(16.0),
        child: Column
        (
          mainAxisAlignment: MainAxisAlignment.center,
          children:
          [
            Image.asset('assets/images/logo.png'),
            const SizedBox(height: 16),
            TextField
            (
              decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
            ),
            TextField
            (
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Row
            (
              children:
              [
                Expanded
                (
                  child: RadioListTile
                  (
                    title: const Text('Người dùng'),
                    value: 'user',
                    groupValue: _role,
                    onChanged: (value)
                    {
                      setState(()
                      {
                        _role = value!;
                      });
                    },
                  ),
                ),
                Expanded
                (
                  child: RadioListTile
                  (
                    title: const Text('Thủ thư'),
                    value: 'librarian',
                    groupValue: _role,
                    onChanged: (value)
                    {
                      setState(()
                      {
                        _role = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton
            (
              onPressed: ()
              {
                // TODO: Xử lý đăng nhập và điều hướng theo vai trò
                if (_role == 'user')
                {
                  Navigator.pushReplacementNamed(context, '/userHome');
                }
                else
                {
                  Navigator.pushReplacementNamed(context, '/librarianHome');
                }
              },
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}