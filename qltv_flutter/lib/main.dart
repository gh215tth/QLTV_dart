import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/librarian_home.dart' as librarian;
import 'screens/user_home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Thư viện',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (c) => const LoginScreen(),
        '/userHome': (c) => const UserHome(),
        '/librarianHome': (c) => const librarian.LibrarianHome(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Chào mừng đến $title!')),
    );
  }
}
