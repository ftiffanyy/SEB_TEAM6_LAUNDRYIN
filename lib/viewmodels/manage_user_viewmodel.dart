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

    final existingByUsername =
        await _firestoreService.getUserByUsername(username.trim());
    if (existingByUsername != null) {
      throw Exception('Username sudah digunakan. Silakan pilih username lain.');
    }

    final existingByPhone = await _firestoreService.getUserByPhone(normalizedPhone);
    if (existingByPhone != null) {
      throw Exception('Nomor telepon sudah terdaftar.');
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
      password: null,
      phone: normalizedPhone,
      address: address?.trim(),
      fcmToken: null,
      role: role,
    );

    await _firestoreService.updateUser(user);
  }

  Future<void> resetUserPassword(int userId) async {
    await _firestoreService.resetUserPassword(userId);
  }
}
