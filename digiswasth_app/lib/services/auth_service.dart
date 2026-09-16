import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyFullName = 'fullName';
  static const String _keyDigiSwasthId = 'digiswasthId';
  static const String _keyToken = 'token';

  // Save login state
  static Future<void> saveLoginState({
    required String fullName,
    required String digiswasthId,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyFullName, fullName);
    await prefs.setString(_keyDigiSwasthId, digiswasthId);
    await prefs.setString(_keyToken, token);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get saved user data
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fullName': prefs.getString(_keyFullName),
      'digiswasthId': prefs.getString(_keyDigiSwasthId),
      'token': prefs.getString(_keyToken),
    };
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}