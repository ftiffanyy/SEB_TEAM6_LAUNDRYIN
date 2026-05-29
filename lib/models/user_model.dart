class UserModel {
  final int userId;
  final String name;
  final String? username;
  final String? password;
  final String phone;
  final String? address;
  final String? fcmToken;
  final String role;

  UserModel({
    required this.userId,
    required this.name,
    this.username,
    this.password,
    required this.phone,
    this.address,
    this.fcmToken,
    required this.role,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      userId: data['user_id'] ?? 0,
      name: data['name'] ?? '',
      username: data['username'],
      password: data['password'],
      phone: data['phone'] ?? '',
      address: data['address'],
      fcmToken: data['fcm_token'],
      role: data['role'] ?? 'Customer',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'name': name,
      'username': username,
      'password': password,
      'phone': phone,
      'address': address,
      'fcm_token': fcmToken,
      'role': role,
    };
  }
}