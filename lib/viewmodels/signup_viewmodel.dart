import '../models/user_model.dart';
import '../services/auth_service.dart';

class SignupViewModel {
  final AuthService _authService = AuthService();

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap diperlukan.';
    }
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username diperlukan.';
    }
    if (value.trim().length < 4) {
      return 'Username minimal 4 karakter.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password diperlukan.';
    }
    if (value.trim().length < 6) {
      return 'Password minimal 6 karakter.';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor telepon diperlukan.';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 9 || cleaned.length > 15) {
      return 'Masukkan nomor telepon yang valid.';
    }
    return null;
  }

  Future<UserModel> signUp({
    required String name,
    required String username,
    required String password,
    required String phone,
    String? address,
  }) async {
    return await _authService.registerCustomer(
      name: name,
      username: username,
      password: password,
      phone: phone,
      address: address,
    );
  }
}
