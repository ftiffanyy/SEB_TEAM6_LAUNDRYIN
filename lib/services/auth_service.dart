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

    // 3. Cek username sudah dipakai orang lain
    final existingByUsername =
        await _firestoreService.getUserByUsername(trimmedUsername);
    if (existingByUsername != null) {
      throw AuthException(
          'Username sudah digunakan. Silakan pilih username lain.');
    }

    // 4. Cek phone sudah ada atau belum
    final existingByPhone =
        await _firestoreService.getUserByPhone(normalizedPhone);

    if (existingByPhone != null) {
      // Phone sudah ada, cek apakah sudah full registered
      final sudahRegistered = existingByPhone.username != null &&
          existingByPhone.username!.isNotEmpty;

      if (sudahRegistered) {
        throw AuthException(
            'Nomor telepon ini sudah terdaftar. Silakan login.');
      }

      // Guest user dari order admin → upgrade ke full account
      final upgraded = UserModel(
        userId: existingByPhone.userId,
        name: name.trim(),
        username: trimmedUsername,
        password: hashPassword(password.trim()),
        phone: normalizedPhone,
        address: address?.trim() ?? existingByPhone.address,
        fcmToken: existingByPhone.fcmToken,
        role: 'Customer',
      );

      await _firestoreService.updateUser(upgraded);
      return upgraded;
    }

    // 5. Phone belum ada sama sekali → buat user baru
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