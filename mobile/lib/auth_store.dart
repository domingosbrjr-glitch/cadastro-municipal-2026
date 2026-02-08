import 'package:shared_preferences/shared_preferences.dart';

class AuthStore {
  static const _kToken = "jwt_token";
  static const _kEmail = "user_email";
  static const _kRole = "user_role";
  static const _kLastSync = "last_sync_iso";

  Future<void> save(String email, String role, String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    await p.setString(_kEmail, email);
    await p.setString(_kRole, role);
  }

  Future<String> token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kToken) ?? "";
  }

  Future<String> email() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kEmail) ?? "";
  }

  Future<String> role() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRole) ?? "";
  }

  Future<String> lastSyncIso() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLastSync) ?? "";
  }

  Future<void> setLastSyncIso(String iso) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLastSync, iso);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kEmail);
    await p.remove(_kRole);
    await p.remove(_kLastSync);
  }
}
