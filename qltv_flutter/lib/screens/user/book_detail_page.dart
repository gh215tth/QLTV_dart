import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class BookDetailPage extends StatefulWidget {
  final int bookId;
  final void Function()? onBorrowed;

  const BookDetailPage({super.key, required this.bookId, this.onBorrowed});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  Map<String, dynamic>? _book;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final book = await ApiService.instance.fetchBookById(widget.bookId);
      if (mounted) {
        setState(() {
          _book = book;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _handleBorrowed() {
    widget.onBorrowed?.call();
    _loadBook(); // cập nhật lại thông tin sách sau khi mượn
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text('❌ Lỗi: $_error')));
    }
    if (_book == null) {
      return const Scaffold(body: Center(child: Text('Không tìm thấy sách')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sách')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Icon(Icons.book, size: 80, color: Colors.indigo)),
            const SizedBox(height: 16),
            Text('📖 Tên sách: ${_book!['title']}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('✍️ Tác giả: ${_book!['author'] ?? 'Không rõ'}'),
            Text('📚 Danh mục: ${_book!['category_name'] ?? 'Không rõ'}'),
            Text('📦 Số lượng còn: ${_book!['quantity']}'),
            Text('🔥 Đã được mượn: ${_book!['total_borrowed'] ?? 0} lần'),
            const SizedBox(height: 24),
            BorrowButton(book: _book!, onBorrowed: _handleBorrowed),
          ],
        ),
      ),
    );
  }
}

class BorrowButton extends StatefulWidget {
  final Map<String, dynamic> book;
  final void Function()? onBorrowed;

  const BorrowButton({super.key, required this.book, this.onBorrowed});

  @override
  State<BorrowButton> createState() => _BorrowButtonState();
}

class _BorrowButtonState extends State<BorrowButton> {
  bool _isBorrowed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkBorrowedStatus();
  }

  Future<void> _checkBorrowedStatus() async {
    try {
      final user = await ApiService.instance.getCurrentUser();
      final borrowed = await ApiService.instance.getBorrowedBookIds(user['id']);
      if (mounted) {
        setState(() {
          _isBorrowed = borrowed.contains(widget.book['id']);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi kiểm tra mượn sách: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isBorrowed) {
      return const Text(
        '✅ Bạn đã mượn sách này',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      );
    }

    if ((widget.book['quantity'] ?? 0) == 0) {
      return const Text(
        '🚫 Sách đã hết',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showBorrowDialog(context),
        icon: const Icon(Icons.shopping_cart_checkout),
        label: const Text('Mượn sách'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  void _showBorrowDialog(BuildContext context) {
    final today = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy').format(today);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mượn sách: ${widget.book['title']}'),
        content: Text('Ngày mượn: $formattedDate'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _borrowBook(context, today);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _borrowBook(BuildContext context, DateTime loanDate) async {
    try {
      final user = await ApiService.instance.getCurrentUser();
      final loan = await ApiService.instance.createLoan({
        'user_id': user['id'],
        'loan_date': loanDate.toIso8601String().split('T')[0],
      });

      await ApiService.instance.createLoanItem({
        'loan_id': loan['id'],
        'book_id': widget.book['id'],
      });

      if (mounted) {
        setState(() => _isBorrowed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Mượn sách thành công')),
        );
        if (widget.onBorrowed != null) widget.onBorrowed!();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi khi mượn sách: $e')),
        );
      }
    }
  }
}
