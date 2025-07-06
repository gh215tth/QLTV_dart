// screens/user/borrow_history.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class BorrowHistoryPage extends StatefulWidget {
  final VoidCallback? onReturn;

  const BorrowHistoryPage({super.key, this.onReturn});

  @override
  State<BorrowHistoryPage> createState() => _BorrowHistoryPageState();
}

class _BorrowHistoryPageState extends State<BorrowHistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyFuture;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  String _selectedFilter = 'Tất cả';
  List<Map<String, dynamic>> _allHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _historyFuture = ApiService.instance.fetchLoans().then((list) {
      _allHistory = list;
      return list;
    });
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Chưa trả';
    try {
      return _dateFormat.format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  List<Map<String, dynamic>> _filteredHistory() {
    if (_selectedFilter == 'Tất cả') return _allHistory;
    if (_selectedFilter == 'Đã trả') {
      return _allHistory.where((e) => e['return_date'] != null).toList();
    }
    return _allHistory.where((e) => e['return_date'] == null).toList();
  }

  Future<void> _returnLoan(int loanId) async {
    try {
      await ApiService.instance.returnLoan(loanId);
      if (!mounted) return;
      setState(_loadHistory);
      widget.onReturn?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Trả sách thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi khi trả sách: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử mượn sách'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            initialValue: _selectedFilter,
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Tất cả', child: Text('Tất cả')),
              PopupMenuItem(value: 'Đã trả', child: Text('Đã trả')),
              PopupMenuItem(value: 'Chưa trả', child: Text('Chưa trả')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '❌ Lỗi khi tải lịch sử:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final filtered = _filteredHistory();
          if (filtered.isEmpty) {
            return const Center(child: Text('Không có dữ liệu phù hợp.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final loanDate = _formatDate(item['loan_date'] as String?);
              final returnDate = _formatDate(item['return_date'] as String?);
              final isReturned = item['return_date'] != null;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.book, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['title'] ?? 'Không rõ tiêu đề',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('📅 Ngày mượn: $loanDate'),
                      Text('📦 Ngày trả: $returnDate'),
                      Text(
                        '⏱️ Trạng thái: ${isReturned ? 'Đã trả' : 'Chưa trả'}',
                        style: TextStyle(
                          color: isReturned ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isReturned)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.assignment_return),
                            label: const Text('Trả sách'),
                            onPressed: () => _returnLoan(item['id'] as int),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
