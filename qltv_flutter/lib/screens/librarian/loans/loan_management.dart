import 'package:flutter/material.dart';
import 'loan_detail_page.dart';
import 'edit_loan_page.dart';
import '../../../services/api_service.dart';

/// Màn hình dành cho thủ thư quản lý danh sách phiếu mượn
class LoanManagementPage extends StatefulWidget {
  const LoanManagementPage({super.key});

  @override
  State<LoanManagementPage> createState() => _LoanManagementPageState();
}

class _LoanManagementPageState extends State<LoanManagementPage> {
  late Future<List<Map<String, dynamic>>> _loansFuture;

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  /// Tải danh sách phiếu mượn từ server (dành cho thủ thư)
  void _fetchLoans() {
    _loansFuture = ApiService.instance.fetchAllLoans();
  }

  /// Làm mới danh sách phiếu mượn
  void _refreshLoans() {
    setState(() {
      _loansFuture = ApiService.instance.fetchAllLoans();
    });
  }

  /// Hiển thị hộp thoại xác nhận và thực hiện xóa phiếu mượn
  Future<void> _deleteLoan(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa phiếu mượn này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.instance.deleteLoan(id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa phiếu mượn.')));
        _refreshLoans();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  /// Hiển thị thông tin một phiếu mượn dưới dạng ListTile
  Widget _buildLoanTile(Map<String, dynamic> loan) {
    final loanId = loan['id'];
    final userName = loan['username'] ?? 'Không rõ';
    final borrowDate = loan['loan_date'] ?? '';
    final status = loan['status'] ?? 'Không rõ';
    final statusColor = status == 'Đã trả' ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text('Phiếu #$loanId - Người mượn: $userName'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngày mượn: $borrowDate'),
            Text('Trạng thái: $status', style: TextStyle(color: statusColor)),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditLoanPage(loanId: loanId),
                ),
              );
              if (result == true) _refreshLoans();
            } else if (value == 'delete') {
              await _deleteLoan(loanId);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
            const PopupMenuItem(value: 'delete', child: Text('Xóa')),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LoanDetailPage(loanId: loanId),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phiếu mượn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _refreshLoans,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final loans = snapshot.data ?? [];
          if (loans.isEmpty) {
            return const Center(child: Text('Chưa có phiếu mượn nào.'));
          }

          return ListView.builder(
            itemCount: loans.length,
            itemBuilder: (context, index) => _buildLoanTile(loans[index]),
          );
        },
      ),
    );
  }
}
