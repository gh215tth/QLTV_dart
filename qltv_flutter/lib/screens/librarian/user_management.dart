// screens/user_management.dart
import 'package:flutter/material.dart';
import 'add_user_page.dart';
import 'edit_user_page.dart';
import '../../services/api_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _usersFuture = ApiService.instance.fetchUsers();
  }

  Future<void> _deleteUser(int id) async {
    try {
      await ApiService.instance.deleteUser(id);
      if (!mounted) return;
      setState(() => _loadUsers());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa người dùng thành công')),
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi khi tải người dùng:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final users = snapshot.data!;
        return Scaffold(
          body: users.isEmpty
              ? const Center(child: Text('Chưa có người dùng nào.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(user['username'] ?? ''),
                        subtitle: Text(user['email'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => EditUserPage(user: user)),
                                );
                                if (updated == true) setState(() => _loadUsers());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteUser(user['id'] as int),
                            ),
                          ],
                        ),
                      ),
                      
                    );
                  },
                ),
          // ở cuối UserManagementPage build:
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddUserPage()),
              );
              if (created == true) setState(() => _loadUsers());
            },
          ),
        );
      },
    );
  }
}
