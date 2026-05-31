import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/user_model.dart';
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
    final normalizedPhone = _normalizePhone(phone);
    if (normalizedPhone.isEmpty) {
      throw AuthException('Nomor telepon tidak valid.');
    }

    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) {
      throw AuthException('Username tidak boleh kosong.');
    }

    final existingUsername = await _firestoreService.getUserByUsername(trimmedUsername);
    if (existingUsername != null) {
      throw AuthException('Username sudah digunakan. Silakan pilih username lain.');
    }

    final usersWithPhone = await _firestoreService.getUsersByPhone(normalizedPhone);
    final registeredUsers = usersWithPhone
        .where((user) => user.username != null && user.username!.isNotEmpty)
        .toList();

    if (registeredUsers.isNotEmpty) {
      throw AuthException('Nomor telepon ini sudah terdaftar. Silakan login.');
    }

    final guestUsers = usersWithPhone
        .where((user) => user.username == null || user.username!.isEmpty)
        .toList();

    if (guestUsers.isEmpty) {
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

    final primaryGuest = guestUsers.first;
    final duplicateGuestIds = guestUsers.skip(1).map((user) => user.userId).toList();

    final upgradedUser = UserModel(
      userId: primaryGuest.userId,
      name: name.trim(),
      username: trimmedUsername,
      password: hashPassword(password.trim()),
      phone: normalizedPhone,
      address: address?.trim() ?? primaryGuest.address,
      fcmToken: primaryGuest.fcmToken,
      role: 'Customer',
    );

    await _firestoreService.updateUser(upgradedUser);
    await _firestoreService.transferOrdersToUser(duplicateGuestIds, upgradedUser.userId);

    return upgradedUser;
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
