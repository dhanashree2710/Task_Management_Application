import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? userId;
  String? role;
  String? name;
  String? email;

  /// SAVE SESSION
  Future<void> setUser({
    required String id,
    required String userRole,
    required String userName,
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    userId = id;
    role = userRole;
    name = userName;
    email = userEmail;

    await prefs.setString('userId', id);
    await prefs.setString('role', userRole);
    await prefs.setString('name', userName);
    await prefs.setString('email', userEmail);
    await prefs.setBool('loggedIn', true);
  }

  /// RESTORE SESSION
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    userId = prefs.getString('userId');
    role = prefs.getString('role');
    name = prefs.getString('name');
    email = prefs.getString('email');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('loggedIn') ?? false;
  }

  Future<void> enableBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric', value);
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric') ?? false;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    userId = null;
    role = null;
    name = null;
    email = null;
  }
}
