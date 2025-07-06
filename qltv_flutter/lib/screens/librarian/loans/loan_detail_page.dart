import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';

class LoanDetailPage extends StatefulWidget {
  final int loanId;
  const LoanDetailPage({super.key, required this.loanId});

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  late Future<Map<String, dynamic>> _loanFuture;

  @override
  void initState() {
    super.initState();
    _loanFuture = ApiService.instance.fetchLoanWithItems(widget.loanId);
  }

  /// Xây dựng phần thông tin chính của phiếu mượn
  Widget _buildLoanInfo(Map<String, dynamic> loan) {
    final loanId = loan['loan_id'];
    final userName = loan['user_name'];
    final loanDate = loan['loan_date'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(loan['loan_date']))
        : 'Không rõ';

    final List items = loan['items'] ?? [];
    final allReturned = items.every((item) => item['return_date'] != null);

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📄 Phiếu mượn #$loanId',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('👤 Người mượn: $userName'),
            Text('📅 Ngày mượn: $loanDate'),
            Text('📦 Ngày trả: ${allReturned ? _findLatestReturnDate(items) : 'Chưa trả'}'),
            Text(
              '⏱️ Trạng thái: ${allReturned ? 'Đã trả' : 'Chưa trả'}',
              style: TextStyle(
                color: allReturned ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trả về ngày trả gần nhất trong danh sách item (nếu tất cả đã trả)
  String _findLatestReturnDate(List items) {
    final dates = items
        .map((e) => e['return_date'])
        .where((d) => d != null)
        .map((d) => DateTime.parse(d))
        .toList();

    if (dates.isEmpty) return 'Chưa trả';
    final latest = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    return DateFormat('dd/MM/yyyy').format(latest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết phiếu mượn')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final loan = snapshot.data!;
          return ListView(
            children: [
              _buildLoanInfo(loan),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('📚 Danh sách sách mượn',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...loan['items'].map<Widget>((item) {
                final returnDate = item['return_date'];
                final isReturned = returnDate != null;
                return ListTile(
                  title: Text(item['title'] ?? 'Không rõ'),
                  subtitle: Text('Tác giả: ${item['author'] ?? '---'}'),
                  trailing: Text(
                    isReturned
                        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(returnDate))
                        : 'Chưa trả',
                    style: TextStyle(color: isReturned ? Colors.green : Colors.red),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
