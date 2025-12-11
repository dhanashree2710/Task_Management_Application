class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;

  UserSession._internal();

  String? userId;
  String? role;
  String? name;
  String? email;

  void setUser({
    required String id,
    required String userRole,
    required String userName,
    required String userEmail,
  }) {
    userId = id;
    role = userRole;
    name = userName;
    email = userEmail;
  }

  void clear() {
    userId = null;
    role = null;
    name = null;
    email = null;
  }
}
