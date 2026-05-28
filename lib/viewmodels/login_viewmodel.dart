import '../models/user_model.dart';
import '../services/firestore_service.dart';

class LoginViewModel {
  final FirestoreService _firestoreService = FirestoreService();

  Future<UserModel?> login(String username, String password) async {
    final users = await _firestoreService.getUsers();

    try {
      return users.firstWhere(
        (user) =>
            user.username == username.trim() &&
            user.password == password.trim(),
      );
    } catch (e) {
      return null;
    }
  }
}