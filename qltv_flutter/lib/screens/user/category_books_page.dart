// screens/user/category_books_page.dart
import 'package:flutter/material.dart';
import 'all_books_page.dart';
import 'category_list_page.dart';

class CategoryBooksPage extends StatefulWidget {
  final void Function()? onBorrowed;

  const CategoryBooksPage({super.key, this.onBorrowed});

  @override
  State<CategoryBooksPage> createState() => _CategoryBooksPageState();
}

class _CategoryBooksPageState extends State<CategoryBooksPage> {
  bool _showBooksDirectly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // hoặc bất kỳ màu sáng nào
        foregroundColor: Colors.black, // đảm bảo icon/text màu tối
        title: const Row(
          children: [
            Icon(Icons.library_books_outlined),
            SizedBox(width: 8),
            Text('Danh mục sách'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showBooksDirectly = !_showBooksDirectly;
              });
            },
            icon: Icon(
              _showBooksDirectly ? Icons.list_alt : Icons.category_outlined,
              color: Colors.blue,
            ),
            label: Text(
              _showBooksDirectly ? 'Theo danh mục' : 'Tất cả sách',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      body: _showBooksDirectly
          ? AllBooksPage(onBorrowed: widget.onBorrowed)
          : CategoryListPage(onBorrowed: widget.onBorrowed),
    );
  }
}
