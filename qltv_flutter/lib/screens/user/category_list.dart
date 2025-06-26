import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class CategoryListPage extends StatelessWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh mục sách')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.instance.fetchCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi khi tải danh mục:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final categories = snapshot.data!;
          if (categories.isEmpty) {
            return const Center(child: Text('Không có danh mục nào.'));
          }

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: const Icon(Icons.category, color: Colors.blue),
                title: Text(category['name'] ?? '', style: const TextStyle(color: Colors.blue)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryBooksPage(
                        categoryId: category['id'],
                        categoryName: category['name'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class CategoryBooksPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryBooksPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryBooksPage> createState() => _CategoryBooksPageState();
}

class _CategoryBooksPageState extends State<CategoryBooksPage> {
  Future<List<Map<String, dynamic>>>? _booksFuture;
  List<int> _borrowedBookIds = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = await ApiService.instance.getCurrentUser();
      final borrowedIds = await ApiService.instance.getBorrowedBookIds(user['id']);
      final books = ApiService.instance.fetchBooksByCategory(widget.categoryId);
      setState(() {
        _borrowedBookIds = borrowedIds;
        _booksFuture = books;
      });
    } catch (e) {
      setState(() {
        _booksFuture = Future.error(e);
      });
    }
  }

  void _onBorrowed() => _fetchData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Danh mục: ${widget.categoryName}')),
      body: _booksFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _booksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi khi tải sách:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final books = snapshot.data!;
                if (books.isEmpty) {
                  return const Center(child: Text('Không có sách trong danh mục này.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final book = books[index];
                    final isBorrowed = _borrowedBookIds.contains(book['id']);
                    final quantity = book['quantity'] ?? 0;

                    Widget trailing;
                    if (isBorrowed) {
                      trailing = const Text('Bạn đã mượn sách', style: TextStyle(color: Colors.orange));
                    } else if (quantity <= 0) {
                      trailing = const Text('Hết sách', style: TextStyle(color: Colors.red));
                    } else {
                      trailing = BorrowButton(book: book, onBorrowed: _onBorrowed);
                    }

                    return ListTile(
                      leading: const Icon(Icons.book),
                      title: Text(book['title'] ?? ''),
                      subtitle: Text(book['author'] ?? 'Không rõ tác giả', style: const TextStyle(fontSize: 13)),
                      trailing: trailing,
                    );
                  },
                );
              },
            ),
    );
  }
}

class BorrowButton extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback onBorrowed;

  const BorrowButton({super.key, required this.book, required this.onBorrowed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showBorrowDialog(context),
      child: const Text('Mượn'),
    );
  }

  void _showBorrowDialog(BuildContext context) {
    DateTime? loanDate;
    DateTime? dueDate;
    final dateFormat = DateFormat('dd/MM/yyyy');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Mượn sách: ${book['title']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDatePicker(
                context,
                title: loanDate == null ? 'Chọn ngày mượn' : dateFormat.format(loanDate!),
                icon: Icons.date_range,
                onPicked: (picked) => setStateDialog(() => loanDate = picked),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              ),
              _buildDatePicker(
                context,
                title: dueDate == null ? 'Ngày dự kiến trả (tùy chọn)' : dateFormat.format(dueDate!),
                icon: Icons.event,
                onPicked: (picked) => setStateDialog(() => dueDate = picked),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                if (loanDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn ngày mượn')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _borrowBook(context, loanDate!, dueDate);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Function(DateTime) onPicked,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  Future<void> _borrowBook(BuildContext context, DateTime loanDate, DateTime? dueDate) async {
    try {
      final user = await ApiService.instance.getCurrentUser();
      final userId = user['id'];
      final bookId = book['id'];

      final borrowed = await ApiService.instance.getBorrowedBookIds(userId);
      if (borrowed.contains(bookId)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Bạn đã mượn sách này và chưa trả.')),
          );
        }
        return;
      }

      final loan = await ApiService.instance.createLoan({
        'user_id': userId,
        'loan_date': loanDate.toIso8601String().split('T')[0],
      });

      await ApiService.instance.createLoanItem({
        'loan_id': loan['id'],
        'book_id': bookId,
        if (dueDate != null) 'return_date': dueDate.toIso8601String().split('T')[0],
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Mượn sách thành công')),
        );
        onBorrowed();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi khi mượn sách: ${e.toString()}')),
        );
      }
    }
  }
}
