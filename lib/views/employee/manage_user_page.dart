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
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadUsers();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String cleanErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery) ||
          (user.username?.toLowerCase().contains(_searchQuery) ?? false) ||
          user.phone.toLowerCase().contains(_searchQuery) ||
          user.role.toLowerCase().contains(_searchQuery);

      final matchesRole =
          _selectedRoleFilter == 'All' || user.role == _selectedRoleFilter;

      return matchesSearch && matchesRole;
    }).toList();
  }

  Future<void> _showUserForm({UserModel? user}) async {
    final nameController = TextEditingController(text: user?.name ?? '');
    final usernameController = TextEditingController(text: user?.username ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final addressController = TextEditingController(text: user?.address ?? '');

    String selectedRole = user?.role ?? 'Customer';
    String dialogError = '';
    bool isSubmitting = false;

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              title: Text(user == null ? 'Tambah User Baru' : 'Edit User'),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (dialogError.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dialogError,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama',
                          ),
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
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            helperText: 'Hanya huruf, angka, dan underscore (_)',
                            helperMaxLines: 2,
                            errorMaxLines: 3,
                          ),
                          validator: (value) {
                            final username = value?.trim() ?? '';

                            if (username.isEmpty) {
                              return 'Username wajib diisi.';
                            }

                            if (RegExp(r'\s').hasMatch(username)) {
                              return 'Username tidak boleh mengandung spasi.';
                            }

                            if (!RegExp(r'^[a-zA-Z0-9_]+$')
                                .hasMatch(username)) {
                              return 'Username hanya boleh huruf, angka, dan underscore (_).';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Telepon',
                          ),
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
                          decoration: const InputDecoration(
                            labelText: 'Alamat (opsional)',
                          ),
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'Cashier',
                              child: Text('Cashier'),
                            ),
                            DropdownMenuItem(
                              value: 'Customer',
                              child: Text('Customer'),
                            ),
                          ],
                          onChanged: isSubmitting
                              ? null
                              : (value) {
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
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = '';
                          });

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

                              Navigator.of(dialogContext).pop();
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

                              Navigator.of(dialogContext).pop();
                              _showSnack('Data user berhasil diperbarui.');
                            }

                            _loadUsers();
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              dialogError = cleanErrorMessage(e);
                            });
                          }
                        },
                  child: Text(
                    isSubmitting
                        ? 'Menyimpan...'
                        : user == null
                            ? 'Simpan'
                            : 'Perbarui',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    addressController.dispose();
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
            'username (${user.username}) dan nomor telepon (${user.phone}) yang sama untuk membuat password baru.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
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
        _showSnack(
          'Gagal reset password: ${cleanErrorMessage(e)}',
          color: Colors.red,
        );
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
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama, username, telepon, atau role...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),

            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Customer', 'Cashier', 'Admin'].map((role) {
                  final isSelected = _selectedRoleFilter == role;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(role),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedRoleFilter = role;
                        });
                      },
                      selectedColor:
                          const Color(0xff4A90E2).withOpacity(0.2),
                      checkmarkColor: const Color(0xff4A90E2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xff4A90E2)
                            : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final allUsers = snapshot.data ?? [];
                  final users = _filterUsers(allUsers);

                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada user. Tambah user baru untuk memulai.',
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 12,
                        headingRowColor: WidgetStateColor.resolveWith(
                          (states) => const Color(0xffF0F4FF),
                        ),
                        columns: const [
                          DataColumn(label: Text('Nama')),
                          DataColumn(label: Text('Username')),
                          DataColumn(label: Text('Telepon')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Aksi')),
                        ],
                        rows: users.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(Text(user.name)),
                              DataCell(Text(user.username ?? '-')),
                              DataCell(Text(user.phone)),
                              DataCell(Text(user.role)),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Edit',
                                      onPressed: () =>
                                          _showUserForm(user: user),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.lock_reset,
                                        color: Colors.orange,
                                      ),
                                      tooltip: 'Reset Password',
                                      onPressed: () =>
                                          _confirmResetPassword(user),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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