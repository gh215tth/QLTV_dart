// screens/librarian/librarian_management.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'add_librarian_page.dart';
import 'edit_librarian_page.dart';

class LibrarianManagementPage extends StatefulWidget {
  const LibrarianManagementPage({super.key});

  @override
  State<LibrarianManagementPage> createState() => _LibrarianManagementPageState();
}

class _LibrarianManagementPageState extends State<LibrarianManagementPage> {
  late Future<List<Map<String, dynamic>>> _librariansFuture;

  @override
  void initState() {
    super.initState();
    _loadLibrarians();
  }

  void _loadLibrarians() {
    _librariansFuture = ApiService.instance.fetchLibrarians();
  }

  Future<void> _deleteLibrarian(int id) async {
    try {
      await ApiService.instance.deleteLibrarian(id);
      if (!mounted) return;
      setState(() => _loadLibrarians());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa thủ thư thành công')),
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
      appBar: AppBar(title: const Text('Quản lý Thủ thư')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _librariansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi khi tải thủ thư:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final librarians = snapshot.data!;
          if (librarians.isEmpty) {
            return const Center(child: Text('Chưa có thủ thư nào.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: librarians.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final librarian = librarians[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(librarian['username'] ?? ''),
                  subtitle: Text(librarian['email'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final localContext = context;
                          final updated = await Navigator.push(
                            localContext,
                            MaterialPageRoute(
                              builder: (_) => EditLibrarianPage(librarian: librarian),
                            ),
                          );
                          if (!mounted) return;
                          if (updated == true) setState(() => _loadLibrarians());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xác nhận'),
                              content: const Text('Bạn có chắc muốn xóa thủ thư này?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _deleteLibrarian(librarian['id'] as int);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final localContext = context;
          final created = await Navigator.push(
            localContext,
            MaterialPageRoute(builder: (_) => const AddLibrarianPage()),
          );
          if (!mounted) return;
          if (created == true) setState(() => _loadLibrarians());
        },
      ),
    );
  }
}
