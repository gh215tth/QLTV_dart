// main.dart
import 'package:flutter/material.dart';
import 'screens/login/login_screen.dart';
import 'screens/librarian/librarian_home.dart' as librarian;
import 'screens/user/user_home.dart';

void main() {
  runApp(const MyApp());
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
