import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CadastroMunicipalApp());
}

class CadastroMunicipalApp extends StatefulWidget {
  const CadastroMunicipalApp({super.key});

  @override
  State<CadastroMunicipalApp> createState() => _CadastroMunicipalAppState();
}

class _CadastroMunicipalAppState extends State<CadastroMunicipalApp> {
  late Future<String> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = _loadToken();
  }

  Future<String> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _tokenFuture,
      builder: (context, snapshot) {
        final token = snapshot.data ?? '';
        final isLogged = token.isNotEmpty;

        return MaterialApp(
          title: 'Cadastro Municipal Offline',
          theme: ThemeData(useMaterial3: true),

          // ✅ Resolve a tela cinza: sempre existe rota inicial
          home: isLogged ? const HomeScreen() : const LoginScreen(),

          // ✅ Rotas nomeadas
          routes: {
            "/": (_) => isLogged ? const HomeScreen() : const LoginScreen(),
            "/login": (_) => const LoginScreen(),
            "/home": (_) => const HomeScreen(),
          },

          // ✅ Se alguma rota inexistente for chamada, não trava
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text("Erro")),
              body: Center(
                child: Text("Rota não encontrada: ${settings.name}"),
              ),
            ),
          ),
        );
      },
    );
  }
}
