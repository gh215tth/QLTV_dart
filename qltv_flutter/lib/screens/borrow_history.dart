import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BorrowHistoryPage extends StatefulWidget {
  const BorrowHistoryPage({super.key});

  @override
  State<BorrowHistoryPage> createState() => _BorrowHistoryPageState();
}

class _BorrowHistoryPageState extends State<BorrowHistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _historyFuture = ApiService.instance.fetchLoans();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
        final history = snapshot.data!;
        if (history.isEmpty) {
          return const Center(child: Text('Chưa có lịch sử mượn.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final item = history[index];
            return ListTile(
              title: Text(item['title'] ?? ''),
              subtitle: Text(
                'Ngày mượn: ${item['loan_date']}\n'
                'Trạng thái: ${item['status']}',
              ),
              onTap: () {
                // TODO: Chi tiết mượn / trả sách
              },
            );
          },
        );
      },
    );
  }
}
