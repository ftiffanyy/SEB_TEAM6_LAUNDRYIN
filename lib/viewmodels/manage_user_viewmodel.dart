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

  String normalizeUsername(String username) {
    return username.trim();
  }

  void validateUsernameFormat(String username) {
    final trimmedUsername = username.trim();

    if (trimmedUsername.isEmpty) {
      throw Exception('Username wajib diisi.');
    }

    if (RegExp(r'\s').hasMatch(trimmedUsername)) {
      throw Exception('Username tidak boleh mengandung spasi.');
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmedUsername)) {
      throw Exception(
        'Username hanya boleh menggunakan huruf, angka, dan underscore (_).',
      );
    }
  }

  Future<void> addUser({
    required String name,
    required String username,
    required String phone,
    required String role,
    String? address,
  }) async {
    final trimmedName = name.trim();
    final trimmedUsername = normalizeUsername(username);
    final normalizedPhone = PhoneHelper.normalize(phone);
    final trimmedAddress = address?.trim();

    validateUsernameFormat(trimmedUsername);

    if (trimmedName.isEmpty || normalizedPhone.isEmpty) {
      throw Exception('Nama, username, dan nomor telepon wajib diisi.');
    }

    final existingByPhone =
        await _firestoreService.getUserByPhone(normalizedPhone);

    if (existingByPhone != null) {
      if (existingByPhone.password == null) {
        if (trimmedUsername != existingByPhone.username) {
          final existingByNewUsername =
              await _firestoreService.getUserByUsername(trimmedUsername);

          if (existingByNewUsername != null &&
              existingByNewUsername.userId != existingByPhone.userId) {
            throw Exception('Username sudah digunakan oleh pengguna lain.');
          }
        }

        final updated = UserModel(
          userId: existingByPhone.userId,
          name: trimmedName,
          username: trimmedUsername,
          password: null,
          phone: normalizedPhone,
          address: trimmedAddress == null || trimmedAddress.isEmpty
              ? null
              : trimmedAddress,
          fcmToken: existingByPhone.fcmToken,
          role: role,
        );

        await _firestoreService.updateUser(updated);
        return;
      } else {
        throw Exception(
          'Nomor telepon sudah terdaftar. Gunakan nomor telepon lain.',
        );
      }
    }

    final existingByUsername =
        await _firestoreService.getUserByUsername(trimmedUsername);

    if (existingByUsername != null) {
      throw Exception('Username sudah digunakan. Silakan pilih username lain.');
    }

    final nextId = await getNextUserId();

    final user = UserModel(
      userId: nextId,
      name: trimmedName,
      username: trimmedUsername,
      password: null,
      phone: normalizedPhone,
      address: trimmedAddress == null || trimmedAddress.isEmpty
          ? null
          : trimmedAddress,
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
    final trimmedName = name.trim();
    final trimmedUsername = normalizeUsername(username);
    final normalizedPhone = PhoneHelper.normalize(phone);
    final trimmedAddress = address?.trim();

    validateUsernameFormat(trimmedUsername);

    if (trimmedName.isEmpty || normalizedPhone.isEmpty) {
      throw Exception('Nama, username, dan nomor telepon wajib diisi.');
    }

    final existingUser = (await _firestoreService.getUsers()).firstWhere(
      (u) => u.userId == userId,
      orElse: () => throw Exception('User tidak ditemukan'),
    );

    final existingByUsername =
        await _firestoreService.getUserByUsername(trimmedUsername);

    if (existingByUsername != null && existingByUsername.userId != userId) {
      throw Exception('Username sudah digunakan oleh pengguna lain.');
    }

    final existingByPhone =
        await _firestoreService.getUserByPhone(normalizedPhone);

    if (existingByPhone != null && existingByPhone.userId != userId) {
      throw Exception('Nomor telepon sudah terdaftar oleh pengguna lain.');
    }

    final user = UserModel(
      userId: userId,
      name: trimmedName,
      username: trimmedUsername,
      password: existingUser.password,
      phone: normalizedPhone,
      address: trimmedAddress == null || trimmedAddress.isEmpty
          ? null
          : trimmedAddress,
      fcmToken: existingUser.fcmToken,
      role: role,
    );

    await _firestoreService.updateUser(user);
  }

  Future<void> resetUserPassword(int userId) async {
    await _firestoreService.resetUserPassword(userId);
  }
}