// screens/user/borrow_history.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class BorrowHistoryPage extends StatefulWidget {
  const BorrowHistoryPage({super.key});

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trả sách thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi trả sách: $e')),
      );
    }
  }

  Future<void> _deleteLoan(int loanId) async {
    try {
      await ApiService.instance.deleteLoan(loanId);
      if (!mounted) return;
      setState(_loadHistory);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa phiếu mượn thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử mượn sách'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: _selectedFilter,
              underline: const SizedBox(),
              dropdownColor: Colors.white,
              items: const [
                DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                DropdownMenuItem(value: 'Đã trả', child: Text('Đã trả')),
                DropdownMenuItem(value: 'Chưa trả', child: Text('Chưa trả')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFilter = value);
                }
              },
            ),
          )
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
                'Lỗi khi tải lịch sử:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
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
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final loanDate = _formatDate(item['loan_date'] as String?);
              final returnDate = _formatDate(item['return_date'] as String?);
              final status = item['return_date'] != null ? 'Đã trả' : 'Chưa trả';

              return ListTile(
                leading: const Icon(Icons.book),
                title: Text(item['title'] ?? 'Không rõ tiêu đề'),
                subtitle: Text(
                  'Ngày mượn: $loanDate\n'
                  'Ngày trả: $returnDate\n'
                  'Trạng thái: $status',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item['return_date'] == null)
                      IconButton(
                        icon: const Icon(Icons.assignment_return),
                        tooltip: 'Trả sách',
                        onPressed: () => _returnLoan(item['id'] as int),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.delete_forever),
                        tooltip: 'Xóa lịch sử',
                        onPressed: () => _deleteLoan(item['id'] as int),
                      )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
