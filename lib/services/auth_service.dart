import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/user_model.dart';
import '../utils/phone_helper.dart';
import 'firestore_service.dart';

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final FirestoreService _firestoreService = FirestoreService();

  Future<UserModel?> login(String username, String password) async {
    final user = await _firestoreService.getUserByUsername(username.trim());
    if (user == null || user.password == null) return null;

    final cleanedPassword = password.trim();
    final hashedPassword = hashPassword(cleanedPassword);

    if (user.password == cleanedPassword || user.password == hashedPassword) {
      return user;
    }

    return null;
  }

  Future<UserModel> registerCustomer({
    required String name,
    required String username,
    required String password,
    required String phone,
    String? address,
  }) async {
    // 1. Normalize & validasi phone (fix: sekarang handle +62, 62, 8)
    final normalizedPhone = PhoneHelper.normalize(phone);
    if (normalizedPhone.isEmpty) {
      throw AuthException('Nomor telepon tidak valid.');
    }

    // 2. Validasi username tidak kosong
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) {
      throw AuthException('Username tidak boleh kosong.');
    }

    // 3. Cek phone sudah ada atau belum (PRIORITAS: phone adalah identifier utama)
    final existingByPhone =
        await _firestoreService.getUserByPhone(normalizedPhone);

    if (existingByPhone != null) {
      // Phone sudah ada, cek status password (null = belum login / sudah di-reset)
      final passwordIsNull = existingByPhone.password == null;

      if (passwordIsNull) {
        // User di-reset oleh admin atau belum fully registered
        // Cek apakah username yang diberikan sesuai dengan yang terdaftar
        if (existingByPhone.username != null && 
            existingByPhone.username!.isNotEmpty &&
            existingByPhone.username != trimmedUsername) {
          throw AuthException(
              'Username tidak sesuai dengan nomor telepon yang terdaftar. '
              'Silakan gunakan username: ${existingByPhone.username}');
        }

        // Upgrade dengan password baru
        final upgraded = UserModel(
          userId: existingByPhone.userId,
          name: name.trim(),
          username: trimmedUsername,
          password: hashPassword(password.trim()),
          phone: normalizedPhone,
          address: address?.trim() ?? existingByPhone.address,
          fcmToken: existingByPhone.fcmToken,
          role: existingByPhone.role,
        );

        await _firestoreService.updateUser(upgraded);
        return upgraded;
      } else {
        // Password sudah ada (sudah fully registered)
        throw AuthException(
            'Nomor telepon ini sudah terdaftar. Silakan login.');
      }
    }

    // 4. Phone belum ada sama sekali → cek username juga tidak ada
    final existingByUsername =
        await _firestoreService.getUserByUsername(trimmedUsername);
    if (existingByUsername != null) {
      throw AuthException(
          'Username sudah digunakan. Silakan pilih username lain.');
    }

    // 5. Buat user baru
    final nextId = await _firestoreService.getNextUserId();
    final newUser = UserModel(
      userId: nextId,
      name: name.trim(),
      username: trimmedUsername,
      password: hashPassword(password.trim()),
      phone: normalizedPhone,
      address: address?.trim(),
      fcmToken: null,
      role: 'Customer',
    );

    await _firestoreService.addUser(newUser);
    return newUser;
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}