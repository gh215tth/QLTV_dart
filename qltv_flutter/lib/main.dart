// main.dart
import 'package:flutter/material.dart';
import 'screens/login/login_screen.dart';
import 'screens/librarian/librarian_home.dart' as librarian;
import 'screens/user/user_home.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ApiService.instance.fetchAndSaveHostIP();
    print('✅ Đã lưu IP backend thành công');
  } catch (e) {
    print('❌ Lỗi lấy IP backend: $e');
  }

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Thư viện',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/userHome': (context) => const UserHome(),
        '/librarianHome': (context) => const librarian.LibrarianHome(),
      },
    );
  }
}
