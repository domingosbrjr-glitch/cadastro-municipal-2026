import 'package:flutter/material.dart';
import '../api.dart';
import '../auth_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  final Api api = Api();
  final AuthStore store = AuthStore();

  Future<void> _doLogin() async {
    setState(() => _loading = true);
    try {
      final token = await api.login(_email.text.trim(), _pass.text);
      final me = await api.me(token);
      await store.save(me["email"] as String, me["role"] as String, token);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed("/home");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entrar")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: "E-mail")),
            TextField(controller: _pass, decoration: const InputDecoration(labelText: "Senha"), obscureText: true),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _doLogin,
              child: _loading ? const CircularProgressIndicator() : const Text("Entrar"),
            ),
          ],
        ),
      ),
    );
  }
}
