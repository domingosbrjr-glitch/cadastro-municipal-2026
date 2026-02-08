import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class Api {
  Future<String> login(String email, String password) async {
    final resp = await http.post(
      Uri.parse("$cloudBaseUrl/auth/login"),
      headers: {"Content-Type":"application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    if (resp.statusCode >= 300) {
      throw Exception("Login falhou: ${resp.statusCode}");
    }
    final data = jsonDecode(resp.body) as Map<String,dynamic>;
    return data["access_token"] as String;
  }

  Future<Map<String,dynamic>> me(String token) async {
    final resp = await http.get(
      Uri.parse("$cloudBaseUrl/me"),
      headers: {"Authorization":"Bearer $token"},
    );
    if (resp.statusCode >= 300) {
      throw Exception("Falha /me: ${resp.statusCode}");
    }
    return jsonDecode(resp.body) as Map<String,dynamic>;
  }

  Future<Map<String,dynamic>> pull(String token, {String sinceIso = ""}) async {
    final uri = Uri.parse("$cloudBaseUrl/sync/pull${sinceIso.isEmpty ? "" : "?since=$sinceIso"}");
    final resp = await http.get(uri, headers: {"Authorization":"Bearer $token"});
    if (resp.statusCode >= 300) {
      throw Exception("Pull falhou: ${resp.statusCode}");
    }
    return jsonDecode(resp.body) as Map<String,dynamic>;
  }
}
