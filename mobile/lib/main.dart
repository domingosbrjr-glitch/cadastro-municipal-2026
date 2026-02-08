import 'package:flutter/material.dart';
import 'auth_store.dart';
import 'screens/login.dart';
import 'screens/home.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final AuthStore store = AuthStore();
  bool ready = false;
  String token = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    token = await store.token();
    setState(() => ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    return MaterialApp(
  title: 'Cadastro Municipal Offline',
  theme: ThemeData(useMaterial3: true),

  // ✅ Evita erro de rota no Windows
  home: token.isEmpty ? const LoginScreen() : const HomeScreen(),

  // ✅ Mantém navegação por nome funcionando
  routes: {
    "/": (_) => token.isEmpty ? const LoginScreen() : const HomeScreen(),
    "/login": (_) => const LoginScreen(),
    "/home": (_) => const HomeScreen(),
  },
);
