import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../viewmodels/manage_user_viewmodel.dart';

class ManageUserPage extends StatefulWidget {
  const ManageUserPage({super.key});

  @override
  State<ManageUserPage> createState() => _ManageUserPageState();
}

class _ManageUserPageState extends State<ManageUserPage> {
  final ManageUserViewModel viewModel = ManageUserViewModel();
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = viewModel.getUsers();
    });
  }

  void _showSnack(String message, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _showUserForm({UserModel? user}) async {
    final nameController = TextEditingController(text: user?.name ?? '');
    final usernameController = TextEditingController(text: user?.username ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final addressController = TextEditingController(text: user?.address ?? '');
    String selectedRole = user?.role ?? 'Customer';
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(user == null ? 'Tambah User Baru' : 'Edit User'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nama'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(labelText: 'Username'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Username wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomor telepon wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Alamat (opsional)'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                          DropdownMenuItem(value: 'Cashier', child: Text('Cashier')),
                          DropdownMenuItem(value: 'Customer', child: Text('Customer')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedRole = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    try {
                      if (user == null) {
                        await viewModel.addUser(
                          name: nameController.text,
                          username: usernameController.text,
                          phone: phoneController.text,
                          address: addressController.text,
                          role: selectedRole,
                        );
                        if (!mounted) return;
                        _showSnack('User berhasil ditambahkan.');
                      } else {
                        await viewModel.updateUser(
                          userId: user.userId,
                          name: nameController.text,
                          username: usernameController.text,
                          phone: phoneController.text,
                          address: addressController.text,
                          role: selectedRole,
                        );
                        if (!mounted) return;
                        _showSnack('Data user berhasil diperbarui.');
                      }

                      if (!mounted) return;
                      Navigator.of(this.context).pop();
                      _loadUsers();
                    } catch (e) {
                      if (!mounted) return;
                      _showSnack(e.toString(), color: Colors.red);
                    }
                  },
                  child: Text(user == null ? 'Simpan' : 'Perbarui'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmResetPassword(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password User'),
          content: Text(
            'Apakah Anda yakin ingin mereset password untuk ${user.name}?\n\n'
            'User akan tidak bisa login dan harus melakukan registrasi ulang dengan '
            'username dan nomor telepon yang sama untuk membuat password baru.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset Password'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirm == true) {
      try {
        await viewModel.resetUserPassword(user.userId);
        _showSnack('Password user berhasil direset.');
        _loadUsers();
      } catch (e) {
        _showSnack('Gagal reset password: $e', color: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage System Users'),
        backgroundColor: const Color(0xff4A90E2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<UserModel>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return const Center(child: Text('Belum ada user. Tambah user baru untuk memulai.'));
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DataTable(
                    columnSpacing: 12,
                    headingRowColor: WidgetStateColor.resolveWith(
                        (states) => const Color(0xfff0f4ff)),
                    columns: const [
                      DataColumn(label: Text('Nama')),
                      DataColumn(label: Text('Username')),
                      DataColumn(label: Text('Telepon')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Aksi')),
                    ],
                    rows: users.map((user) {
                      return DataRow(cells: [
                        DataCell(Text(user.name)),
                        DataCell(Text(user.username ?? '-')),
                        DataCell(Text(user.phone)),
                        DataCell(Text(user.role)),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit',
                              onPressed: () => _showUserForm(user: user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.lock_reset, color: Colors.orange),
                              tooltip: 'Reset Password',
                              onPressed: () => _confirmResetPassword(user),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah User'),
      ),
    );
  }
}
