import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';

class EditLoanPage extends StatefulWidget {
  final int loanId;

  const EditLoanPage({super.key, required this.loanId});

  @override
  State<EditLoanPage> createState() => _EditLoanPageState();
}

class _EditLoanPageState extends State<EditLoanPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _borrowDate;
  bool _isLoading = false;
  late Map<String, dynamic> _loan;

  @override
  void initState() {
    super.initState();
    _loadLoan();
  }

  Future<void> _loadLoan() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.instance.fetchLoanById(widget.loanId);
      setState(() {
        _loan = data;
        _borrowDate = DateTime.tryParse(data['loan_date']);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      Navigator.pop(context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLoan() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ApiService.instance.updateLoan(widget.loanId, {
        'user_id': _loan['user_id'],
        'loan_date': DateFormat('yyyy-MM-dd').format(_borrowDate!),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật phiếu mượn.')));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _pickBorrowDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _borrowDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _borrowDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa phiếu mượn')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Hiển thị User ID không cho chỉnh
                    TextFormField(
                      initialValue: _loan['user_id'].toString(),
                      decoration: const InputDecoration(labelText: 'Mã người mượn'),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    // Ngày mượn
                    InkWell(
                      onTap: _pickBorrowDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày mượn',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _borrowDate != null
                              ? DateFormat('dd/MM/yyyy').format(_borrowDate!)
                              : 'Chọn ngày',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveLoan,
                      child: const Text('Lưu'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
