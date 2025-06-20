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

  @override
  void initState() {
    super.initState();
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
            final rawDate = item['loan_date'] as String? ?? '';
            String loanDate;
            try {
              loanDate = _dateFormat.format(DateTime.parse(rawDate));
            } catch (_) {
              loanDate = rawDate;
            }
            return ListTile(
              title: Text(item['title'] ?? ''),
              subtitle: Text(
                'Ngày mượn: $loanDate\n'
                'Trạng thái: ${item['status']}',
              ),
            );
          },
        );
      },
    );
  }
}
