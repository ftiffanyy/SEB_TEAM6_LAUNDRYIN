import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../utils/phone_helper.dart';

class ManageUserViewModel {
  final FirestoreService _firestoreService = FirestoreService();

  Future<List<UserModel>> getUsers() async {
    return await _firestoreService.getUsers();
  }

  Future<int> getNextUserId() async {
    return await _firestoreService.getNextUserId();
  }

  Future<void> addUser({
    required String name,
    required String username,
    required String phone,
    required String role,
    String? address,
  }) async {
    final normalizedPhone = PhoneHelper.normalize(phone);

    if (name.trim().isEmpty || username.trim().isEmpty || normalizedPhone.isEmpty) {
      throw Exception('Nama, username, dan nomor telepon wajib diisi.');
    }

    final existingByPhone = await _firestoreService.getUserByPhone(normalizedPhone);
    if (existingByPhone != null) {
      // Jika user sudah ada dengan password null (sudah di-reset), izinkan update
      if (existingByPhone.password == null) {
        // Jika username berbeda, cek apakah username baru sudah digunakan
        if (username.trim() != existingByPhone.username) {
          final existingByNewUsername = 
              await _firestoreService.getUserByUsername(username.trim());
          if (existingByNewUsername != null && 
              existingByNewUsername.userId != existingByPhone.userId) {
            throw Exception('Username sudah digunakan oleh pengguna lain.');
          }
        }
        
        // Update user yang sudah di-reset
        final updated = UserModel(
          userId: existingByPhone.userId,
          name: name.trim(),
          username: username.trim(),
          password: null,
          phone: normalizedPhone,
          address: address?.trim(),
          fcmToken: existingByPhone.fcmToken,
          role: role,
        );
        await _firestoreService.updateUser(updated);
        return;
      } else {
        // User sudah fully registered dengan password
        throw Exception('Nomor telepon sudah terdaftar. Gunakan nomor telepon lain.');
      }
    }

    final existingByUsername =
        await _firestoreService.getUserByUsername(username.trim());
    if (existingByUsername != null) {
      throw Exception('Username sudah digunakan. Silakan pilih username lain.');
    }

    final nextId = await getNextUserId();
    final user = UserModel(
      userId: nextId,
      name: name.trim(),
      username: username.trim(),
      password: null,
      phone: normalizedPhone,
      address: address?.trim(),
      fcmToken: null,
      role: role,
    );

    await _firestoreService.addUser(user);
  }

  Future<void> updateUser({
    required int userId,
    required String name,
    required String username,
    required String phone,
    required String role,
    String? address,
  }) async {
    final normalizedPhone = PhoneHelper.normalize(phone);

    if (name.trim().isEmpty || username.trim().isEmpty || normalizedPhone.isEmpty) {
      throw Exception('Nama, username, dan nomor telepon wajib diisi.');
    }

    // Fetch user existing untuk preserve fcmToken dan password
    final existingUser = (await _firestoreService.getUsers())
        .firstWhere((u) => u.userId == userId, orElse: () => throw Exception('User tidak ditemukan'));

    final existingByUsername =
        await _firestoreService.getUserByUsername(username.trim());
    if (existingByUsername != null && existingByUsername.userId != userId) {
      throw Exception('Username sudah digunakan oleh pengguna lain.');
    }

    final existingByPhone = await _firestoreService.getUserByPhone(normalizedPhone);
    if (existingByPhone != null && existingByPhone.userId != userId) {
      throw Exception('Nomor telepon sudah terdaftar oleh pengguna lain.');
    }

    final user = UserModel(
      userId: userId,
      name: name.trim(),
      username: username.trim(),
      password: existingUser.password,
      phone: normalizedPhone,
      address: address?.trim(),
      fcmToken: existingUser.fcmToken,
      role: role,
    );

    await _firestoreService.updateUser(user);
  }

  Future<void> resetUserPassword(int userId) async {
    await _firestoreService.resetUserPassword(userId);
  }
}