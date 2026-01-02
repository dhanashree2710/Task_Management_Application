import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  static const _loggedIn = 'logged_in';
  static const _userId = 'user_id';
  static const _userRole = 'user_role';
  static const _userName = 'user_name';
  static const _userEmail = 'user_email';

  Future<void> setUser({
    required String id,
    required String userRole,
    required String userName,
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedIn, true);
    await prefs.setString(_userId, id);
    await prefs.setString(_userRole, userRole);
    await prefs.setString(_userName, userName);
    await prefs.setString(_userEmail, userEmail);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      await prefs.setBool(_loggedIn, true);
      await prefs.setString(_userId, firebaseUser.uid);
      return true;
    }

    return prefs.getBool(_loggedIn) ?? false;
  }

  Future<String> get userId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userId) ?? '';
  }

  Future<String> get role async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRole) ?? '';
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedIn);
    await prefs.remove(_userId);
    await prefs.remove(_userRole);
    await prefs.remove(_userName);
    await prefs.remove(_userEmail);
  }
}
