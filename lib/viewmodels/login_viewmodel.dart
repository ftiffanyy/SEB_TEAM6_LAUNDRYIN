import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';

class LoginViewModel {
  final FirestoreService _firestoreService = FirestoreService();

  Future<UserModel?> login(String username, String password) async {
    final user = await _firestoreService.getUserByUsername(username.trim());

    if (user == null || user.password == null) return null;

    final hashedInput = _hashPassword(password.trim());

    // Support dua kondisi:
    // 1. Password di DB sudah di-hash (normal, setelah pakai auth_service baru)
    // 2. Password di DB masih plain (data lama sebelum refactor)
    if (user.password == hashedInput || user.password == password.trim()) {
      return user;
    }

    return null;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}